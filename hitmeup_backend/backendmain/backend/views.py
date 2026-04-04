from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta
import secrets

try:
	from google.auth.transport import requests as google_requests
	from google.oauth2 import id_token as google_id_token
	GOOGLE_AUTH_AVAILABLE = True
except Exception:
	GOOGLE_AUTH_AVAILABLE = False
from .models import (
	community,
	communitymessage,
	communitymessagepoll,
	communitymessagepolloption,
	communitymessagepollvote,
	directchat,
	directmessage,
	directmessagepoll,
	directmessagepolloption,
	directmessagepollvote,
	friendrequest,
	user,
	oauthverificationcode,
)
from .serializers import (
	communitySerializer,
	communityMessagePollOptionSerializer,
	communityMessagePollSerializer,
	communityMessagePollVoteSerializer,
	communityMessageSerializer,
	directChatSerializer,
	directMessageSerializer,
	directMessagePollOptionSerializer,
	directMessagePollSerializer,
	directMessagePollVoteSerializer,
	friendRequestSerializer,
	userSerializer,
)

# Create your views here.


class userViewSet(viewsets.ModelViewSet):
	queryset = user.objects.all()
	serializer_class = userSerializer

	@action(detail=False, methods=["post"], url_path="login")
	def login(self, request):
		identifier = str(request.data.get("identifier", "")).strip()
		password = str(request.data.get("password", ""))

		if not identifier or not password:
			return Response(
				{"detail": "identifier and password are required."},
				status=status.HTTP_400_BAD_REQUEST,
			)

		matched_user = user.objects.filter(
			Q(email__iexact=identifier) | Q(name__iexact=identifier),
			password=password,
		).first()

		if matched_user is None:
			return Response(
				{"detail": "Invalid username/email or password."},
				status=status.HTTP_401_UNAUTHORIZED,
			)

		serializer = self.get_serializer(matched_user)
		return Response(serializer.data, status=status.HTTP_200_OK)

	@action(detail=True, methods=["patch"], url_path="edit-user")
	def edit_user(self, request, pk=None):
		user_obj = self.get_object()
		serializer = self.get_serializer(user_obj, data=request.data, partial=True)
		serializer.is_valid(raise_exception=True)
		serializer.save()
		return Response(serializer.data)

	@action(detail=True, methods=["delete"], url_path="delete-user")
	def delete_user(self, request, pk=None):
		user_obj = self.get_object()
		user_obj.delete()
		return Response(status=status.HTTP_204_NO_CONTENT)


def _generate_verification_code():
	return f"{secrets.randbelow(10000):04d}"


def _verify_google_token(id_token_value):
	if not GOOGLE_AUTH_AVAILABLE:
		raise RuntimeError("google-auth is not installed on the backend.")
	return google_id_token.verify_oauth2_token(id_token_value, google_requests.Request())


def _send_verification_email(recipient_email, code_value):
	from django.core.mail import send_mail

	try:
		send_mail(
			subject="Your HitMeUp verification code",
			message=f"Your verification code is {code_value}. It expires in 10 minutes.",
			from_email=settings.DEFAULT_FROM_EMAIL,
			recipient_list=[recipient_email],
			fail_silently=False,
		)
		return True, None
	except Exception as exc:
		return False, str(exc)


@api_view(["POST"])
def oauth_signin(request):
	provider = str(request.data.get("provider", "")).strip().lower()
	id_token_value = str(request.data.get("id_token", "")).strip()
	email = str(request.data.get("email", "")).strip().lower()

	if provider != "google":
		return Response({"detail": "Only Google sign-in is enabled right now."}, status=status.HTTP_400_BAD_REQUEST)

	if not id_token_value:
		return Response({"detail": "id_token is required."}, status=status.HTTP_400_BAD_REQUEST)

	try:
		id_info = _verify_google_token(id_token_value)
	except Exception as exc:
		return Response({"detail": f"Google token verification failed: {exc}"}, status=status.HTTP_400_BAD_REQUEST)

	verified_email = str(id_info.get("email", "")).strip().lower()
	provider_user_id = str(id_info.get("sub", "")).strip()

	if not verified_email:
		return Response({"detail": "Google account did not provide an email address."}, status=status.HTTP_400_BAD_REQUEST)

	if email and email != verified_email:
		return Response({"detail": "Email mismatch between Google token and request."}, status=status.HTTP_400_BAD_REQUEST)

	matched_user = user.objects.filter(email__iexact=verified_email).first()
	if matched_user is None:
		return Response(
			{
				"status": "signup_required",
				"email": verified_email,
				"name": str(id_info.get("name", "")).strip(),
				"identifier": provider_user_id,
				"detail": "No linked account found for this Google email.",
			},
			status=status.HTTP_200_OK,
		)

	serializer = userSerializer(matched_user)
	return Response(
		{
			"status": "linked",
			"user": serializer.data,
		},
		status=status.HTTP_200_OK,
	)


@api_view(["POST"])
def verify_oauth_code(request):
	email = str(request.data.get("email", "")).strip().lower()
	code_value = str(request.data.get("code", "")).strip()
	provider = str(request.data.get("provider", "google")).strip().lower()

	if not email or not code_value:
		return Response({"detail": "email and code are required."}, status=status.HTTP_400_BAD_REQUEST)

	verification = oauthverificationcode.objects.filter(email=email, provider=provider, code=code_value, is_used=False).first()
	if verification is None:
		return Response({"detail": "Invalid verification code."}, status=status.HTTP_400_BAD_REQUEST)

	if verification.has_expired():
		verification.delete()
		return Response({"detail": "Verification code expired."}, status=status.HTTP_400_BAD_REQUEST)

	verification.is_used = True
	verification.save(update_fields=["is_used"])

	matched_user = user.objects.filter(email__iexact=email).first()
	if matched_user is None:
		return Response(
			{
				"detail": "No existing user was found for this Google account. Create or link the account first.",
			},
			status=status.HTTP_404_NOT_FOUND,
		)

	serializer = userSerializer(matched_user)
	return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["POST"])
def resend_oauth_code(request):
	email = str(request.data.get("email", "")).strip().lower()
	provider = str(request.data.get("provider", "google")).strip().lower()

	verification = oauthverificationcode.objects.filter(email=email, provider=provider).first()
	if verification is None:
		return Response({"detail": "No verification request found."}, status=status.HTTP_404_NOT_FOUND)

	code_value = _generate_verification_code()
	verification.code = code_value
	verification.expires_at = timezone.now() + timedelta(minutes=10)
	verification.is_used = False
	verification.save(update_fields=["code", "expires_at", "is_used"])

	email_sent, email_error = _send_verification_email(email, code_value)
	response_payload = {
		"message": "Verification code resent." if email_sent else "Verification code regenerated, but email delivery failed.",
	}
	if not email_sent:
		response_payload["email_error"] = email_error
		if settings.DEBUG:
			response_payload["debug_code"] = code_value

	return Response(response_payload, status=status.HTTP_200_OK)


class communityViewSet(viewsets.ModelViewSet):
	queryset = community.objects.all()
	serializer_class = communitySerializer

	@action(detail=True, methods=["post"], url_path="add-member")
	def add_member(self, request, pk=None):
		"""Add a user to a community"""
		try:
			community_obj = self.get_object()
			user_id = request.data.get("user_id")

			if not user_id:
				return Response(
					{"detail": "user_id is required."},
					status=status.HTTP_400_BAD_REQUEST,
				)

			user_obj = user.objects.filter(id=user_id).first()
			if not user_obj:
				return Response(
					{"detail": "User not found."},
					status=status.HTTP_404_NOT_FOUND,
				)

			# Check if user is already a member
			if community_obj.members.filter(id=user_id).exists():
				return Response(
					{"detail": "User is already a member of this community."},
					status=status.HTTP_200_OK,
				)

			# Add user to community
			community_obj.members.add(user_obj)
			
			# Update totalParticipants
			community_obj.totalParticipants = community_obj.members.count()
			community_obj.save(update_fields=['totalParticipants'])

			return Response(
				{"detail": "User added to community successfully.", "totalParticipants": community_obj.totalParticipants},
				status=status.HTTP_200_OK,
			)
		except Exception as e:
			return Response(
				{"detail": f"Error adding user to community: {str(e)}"},
				status=status.HTTP_400_BAD_REQUEST,
			)

	@action(detail=True, methods=["post"], url_path="remove-member")
	def remove_member(self, request, pk=None):
		"""Remove a user from a community"""
		try:
			community_obj = self.get_object()
			user_id = request.data.get("user_id")

			if not user_id:
				return Response(
					{"detail": "user_id is required."},
					status=status.HTTP_400_BAD_REQUEST,
				)

			user_obj = user.objects.filter(id=user_id).first()
			if not user_obj:
				return Response(
					{"detail": "User not found."},
					status=status.HTTP_404_NOT_FOUND,
				)

			# Check if user is a member
			if not community_obj.members.filter(id=user_id).exists():
				return Response(
					{"detail": "User is not a member of this community."},
					status=status.HTTP_200_OK,
				)

			# Remove user from community
			community_obj.members.remove(user_obj)
			
			# Update totalParticipants
			community_obj.totalParticipants = community_obj.members.count()
			community_obj.save(update_fields=['totalParticipants'])

			return Response(
				{"detail": "User removed from community successfully.", "totalParticipants": community_obj.totalParticipants},
				status=status.HTTP_200_OK,
			)
		except Exception as e:
			return Response(
				{"detail": f"Error removing user from community: {str(e)}"},
				status=status.HTTP_400_BAD_REQUEST,
			)


class communityMessageViewSet(viewsets.ModelViewSet):
	queryset = communitymessage.objects.select_related("community", "sender").all()
	serializer_class = communityMessageSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		community_id = self.request.query_params.get("community")
		if community_id:
			queryset = queryset.filter(community_id=community_id)

		before_id = self.request.query_params.get("before_id")
		limit_value = self.request.query_params.get("limit")

		if before_id:
			queryset = queryset.filter(id__lt=before_id)

		if community_id and limit_value:
			try:
				limit_count = max(1, int(limit_value))
			except ValueError:
				limit_count = 20

			queryset = queryset.order_by("-created_at")[:limit_count]
			return list(queryset)[::-1]

		if community_id and not limit_value:
			queryset = queryset.order_by("created_at")
			return queryset

		return queryset.order_by("-created_at")


class directChatViewSet(viewsets.ModelViewSet):
	queryset = directchat.objects.select_related("user1", "user2").all()
	serializer_class = directChatSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		user_id = self.request.query_params.get("user")
		if user_id:
			current_user = user.objects.prefetch_related("friends").filter(id=user_id).first()
			if current_user is None:
				return queryset.none()

			directchat.ensure_for_user_friends(current_user)
			queryset = queryset.filter(user1_id=user_id) | queryset.filter(user2_id=user_id)
		return queryset.order_by("-updated_at")


class directMessageViewSet(viewsets.ModelViewSet):
	queryset = directmessage.objects.select_related("chat", "sender").all()
	serializer_class = directMessageSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		chat_id = self.request.query_params.get("chat")
		if chat_id:
			queryset = queryset.filter(chat_id=chat_id)

		before_id = self.request.query_params.get("before_id")
		limit_value = self.request.query_params.get("limit")

		if before_id:
			queryset = queryset.filter(id__lt=before_id)

		if chat_id and limit_value:
			try:
				limit_count = max(1, int(limit_value))
			except ValueError:
				limit_count = 20

			queryset = queryset.order_by("-created_at")[:limit_count]
			return list(queryset)[::-1]

		if chat_id and not limit_value:
			queryset = queryset.order_by("created_at")
			return queryset
		return queryset


class friendRequestViewSet(viewsets.ModelViewSet):
	queryset = friendrequest.objects.select_related("requester", "receiver").all()
	serializer_class = friendRequestSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		requester_id = self.request.query_params.get("requester")
		receiver_id = self.request.query_params.get("receiver")
		status_value = self.request.query_params.get("status")

		if requester_id:
			queryset = queryset.filter(requester_id=requester_id)
		if receiver_id:
			queryset = queryset.filter(receiver_id=receiver_id)
		if status_value:
			queryset = queryset.filter(status=status_value)

		return queryset.order_by("-created_at")


class directMessagePollViewSet(viewsets.ReadOnlyModelViewSet):
	queryset = directmessagepoll.objects.prefetch_related("options__votes__voter").all()
	serializer_class = directMessagePollSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		message_id = self.request.query_params.get("message")
		if message_id:
			queryset = queryset.filter(message_id=message_id)
		return queryset


class directMessagePollOptionViewSet(viewsets.ReadOnlyModelViewSet):
	queryset = directmessagepolloption.objects.prefetch_related("votes__voter").all()
	serializer_class = directMessagePollOptionSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		poll_id = self.request.query_params.get("poll")
		if poll_id:
			queryset = queryset.filter(poll_id=poll_id)
		return queryset


class directMessagePollVoteViewSet(viewsets.ModelViewSet):
	queryset = directmessagepollvote.objects.select_related("option", "voter", "option__poll").all()
	serializer_class = directMessagePollVoteSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		option_id = self.request.query_params.get("option")
		poll_id = self.request.query_params.get("poll")

		if option_id:
			queryset = queryset.filter(option_id=option_id)
		if poll_id:
			queryset = queryset.filter(option__poll_id=poll_id)

		return queryset.order_by("-created_at")


class communityMessagePollViewSet(viewsets.ReadOnlyModelViewSet):
	queryset = communitymessagepoll.objects.prefetch_related("options__votes__voter").all()
	serializer_class = communityMessagePollSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		message_id = self.request.query_params.get("message")
		if message_id:
			queryset = queryset.filter(message_id=message_id)
		return queryset


class communityMessagePollOptionViewSet(viewsets.ReadOnlyModelViewSet):
	queryset = communitymessagepolloption.objects.prefetch_related("votes__voter").all()
	serializer_class = communityMessagePollOptionSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		poll_id = self.request.query_params.get("poll")
		if poll_id:
			queryset = queryset.filter(poll_id=poll_id)
		return queryset


class communityMessagePollVoteViewSet(viewsets.ModelViewSet):
	queryset = communitymessagepollvote.objects.select_related("option", "voter", "option__poll").all()
	serializer_class = communityMessagePollVoteSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		option_id = self.request.query_params.get("option")
		poll_id = self.request.query_params.get("poll")

		if option_id:
			queryset = queryset.filter(option_id=option_id)
		if poll_id:
			queryset = queryset.filter(option__poll_id=poll_id)

		return queryset.order_by("-created_at")
