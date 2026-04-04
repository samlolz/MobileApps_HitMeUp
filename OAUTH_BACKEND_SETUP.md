# OAuth Backend API Specifications

This document outlines the required Django REST Framework endpoints for the OAuth authentication flow with Google and Apple services.

## Overview

The OAuth flow works as follows:
1. Frontend collects Google/Apple ID token
2. Sends token to backend OAuth endpoint
3. Backend verifies token and generates a verification code
4. Code is sent to user's email
5. User enters code in verification screen
6. Backend validates code and creates/links user account
7. User is logged in and sent to main app

## Required Endpoints

### 1. OAuth Sign-In Endpoint

**Endpoint:** `POST /api/users/oauth-signin/`

**Purpose:** Exchange OAuth ID token for user email and trigger verification code sending

**Request Body:**
```json
{
  "provider": "google|apple",
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "email": "user@example.com",
  "full_name": "John Doe"
}
```

**Response (200 OK):**
```json
{
  "email": "user@example.com",
  "identifier": "google_user_id or apple_user_id",
  "message": "Verification code sent to email"
}
```

**Response (400 Bad Request):**
```json
{
  "detail": "Invalid token or provider"
}
```

**Backend Implementation Steps:**
1. Validate the ID token using the provider's library:
   - Google: Use `google.auth.transport.requests` to verify
   - Apple: Use Apple's public keys endpoint
2. Extract email and user info from token
3. Generate a random 4-digit verification code
4. Store code in database with expiration (5-10 minutes)
5. Send email with verification code
6. Return email and identifier to frontend

**Python Libraries Needed:**
```bash
pip install google-auth
pip install PyJWT cryptography  # For Apple
pip install django-otp  # For OTP/code storage
```

---

### 2. Verify OAuth Code Endpoint

**Endpoint:** `POST /api/users/verify-oauth-code/`

**Purpose:** Validate verification code and create/authenticate user

**Request Body:**
```json
{
  "email": "user@example.com",
  "code": "1234",
  "identifier": "google_user_id",
  "is_signup": false
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "user",
  "email": "user@example.com",
  "profile_picture": null,
  "gender": null,
  "diamonds": 0,
  "level": 1,
  "created_at": "2026-04-04T12:00:00Z"
}
```

**Response (400 Bad Request):**
```json
{
  "detail": "Invalid or expired code"
}
```

**Backend Implementation Steps:**
1. Lookup verification code by email
2. Check if code matches and hasn't expired
3. If valid:
   - Check if user with email exists
     - If exists: link OAuth provider ID to user (if not already linked)
     - If new: create new user account
   - Delete the used verification code
   - Return full user object
4. If invalid:
   - Return 400 error
   - Optionally track failed attempts and rate-limit

---

### 3. Resend OAuth Code Endpoint

**Endpoint:** `POST /api/users/resend-oauth-code/`

**Purpose:** Resend verification code to user's email

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "message": "Verification code resent"
}
```

**Response (400 Bad Request):**
```json
{
  "detail": "No pending code for this email"
}
```

**Backend Implementation Steps:**
1. Check if there's an active verification code for this email
2. Delete the old code
3. Generate new verification code
4. Send new email
5. Return success message

---

## Database Models

Add to your Django models.py:

```python
from django.db import models
from django.utils import timezone

class OAuthVerificationCode(models.Model):
    PROVIDER_CHOICES = [
        ('google', 'Google'),
        ('apple', 'Apple'),
    ]
    
    email = models.EmailField()
    provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES)
    code = models.CharField(max_length=4)
    identifier = models.CharField(max_length=255, null=True, blank=True)  # OAuth ID from provider
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    
    class Meta:
        unique_together = ('email', 'provider')
        indexes = [
            models.Index(fields=['email', 'code']),
        ]
    
    def is_expired(self):
        return timezone.now() > self.expires_at
    
    def __str__(self):
        return f"{self.email} - {self.provider}"


class OAuthProvider(models.Model):
    PROVIDER_CHOICES = [
        ('google', 'Google'),
        ('apple', 'Apple'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='oauth_providers')
    provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES)
    provider_id = models.CharField(max_length=255)  # OAuth ID from provider
    email = models.EmailField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('provider', 'provider_id')
    
    def __str__(self):
        return f"{self.user.username} - {self.provider}"
```

---

## Django Views Implementation Template

```python
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.core.mail import send_mail
from django.utils import timezone
from datetime import timedelta
import random
import string

@api_view(['POST'])
def oauth_signin(request):
    """Exchange OAuth token for verification code"""
    provider = request.data.get('provider')
    id_token = request.data.get('id_token')
    email = request.data.get('email')
    full_name = request.data.get('full_name')
    
    # TODO: Validate ID token
    # TODO: Extract actual email from token
    
    if not email:
        return Response(
            {'detail': 'Email not provided'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Generate code
    code = ''.join(random.choices(string.digits, k=4))
    
    # Save verification code
    OAuthVerificationCode.objects.update_or_create(
        email=email,
        provider=provider,
        defaults={
            'code': code,
            'identifier': request.data.get('identifier', ''),
            'expires_at': timezone.now() + timedelta(minutes=10),
            'is_used': False,
        }
    )
    
    # Send email
    send_mail(
        subject='Your HitMeUp Verification Code',
        message=f'Your verification code is: {code}\n\nThis code will expire in 10 minutes.',
        from_email='noreply@hitmeup.com',
        recipient_list=[email],
    )
    
    return Response({
        'email': email,
        'identifier': request.data.get('identifier'),
        'message': 'Verification code sent to email'
    })


@api_view(['POST'])
def verify_oauth_code(request):
    """Verify code and create/authenticate user"""
    email = request.data.get('email')
    code = request.data.get('code')
    
    try:
        verification = OAuthVerificationCode.objects.get(email=email, code=code)
    except OAuthVerificationCode.DoesNotExist:
        return Response(
            {'detail': 'Invalid code'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if verification.is_expired():
        verification.delete()
        return Response(
            {'detail': 'Code expired'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Create or get user
    user, created = User.objects.get_or_create(
        email=email,
        defaults={
            'username': email.split('@')[0] + str(random.randint(1000, 9999))
        }
    )
    
    # Mark code as used
    verification.is_used = True
    verification.save()
    
    # Optional: create auth token for future requests
    # token, _ = Token.objects.get_or_create(user=user)
    
    return Response({
        'id': user.id,
        'username': user.username,
        'email': user.email,
        # ... return full user data matching your User serializer
    })
```

---

## Email Template (Optional)

Create an email template for sending codes:

**email_verification_code.html:**
```html
<!DOCTYPE html>
<html>
<head>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
        }
        .container {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
        }
        .code {
            font-size: 32px;
            font-weight: bold;
            color: #448AFF;
            letter-spacing: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h2>Welcome to HitMeUp</h2>
        <p>Your verification code is:</p>
        <div class="code">{{ code }}</div>
        <p>This code will expire in 10 minutes.</p>
        <p>If you didn't request this code, please ignore this email.</p>
    </div>
</body>
</html>
```

---

## Frontend to Backend Integration Notes

1. **Google Setup:**
   - Create OAuth credential in Google Cloud Console
   - Add Android/iOS bundle IDs to OAuth app config
   - Frontend uses `google_sign_in` package

2. **Apple Setup:**
   - Configure Sign in with Apple in Apple Developer Program
   - Add iOS bundle ID
   - Frontend uses `sign_in_with_apple` package

3. **CORS Configuration (if frontend is web):**
   - Add your frontend URL to Django CORS_ALLOWED_ORIGINS

4. **Email Configuration:**
   - Set up EMAIL_BACKEND in settings.py
   - Configure SMTP credentials (Gmail, SendGrid, etc.)
   - Example for Gmail:
     ```python
     EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
     EMAIL_HOST = 'smtp.gmail.com'
     EMAIL_PORT = 587
     EMAIL_USE_TLS = True
     EMAIL_HOST_USER = 'your-email@gmail.com'
     EMAIL_HOST_PASSWORD = 'your-app-password'
     ```

---

## Security Considerations

1. **Token Validation:**
   - Always verify OAuth tokens server-side using provider's public keys
   - Never trust tokens without validation

2. **Code Security:**
   - Codes should be random and not guessable
   - Implement rate limiting on verification attempts
   - Expire codes after 10 minutes

3. **Email Verification:**
   - Store email lowercase for consistency
   - Validate email format before sending

4. **Rate Limiting:**
   ```python
   from django_ratelimit.decorators import ratelimit
   
   @ratelimit(key='ip', rate='5/h', method='POST')
   def oauth_signin(request):
       # implementation
   ```

5. **HTTPS Only:**
   - Always use HTTPS in production
   - Don't send tokens over HTTP

---

## Testing

Test the flow with:
```bash
# Test OAuth sign-in endpoint
curl -X POST http://localhost:8000/api/users/oauth-signin/ \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "google",
    "id_token": "test_token",
    "email": "test@example.com"
  }'

# Test verification endpoint
curl -X POST http://localhost:8000/api/users/verify-oauth-code/ \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "1234"
  }'
```
