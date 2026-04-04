"""
URL configuration for backendmain project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, path
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from backend.views import (
    communityViewSet,
    communityMessagePollOptionViewSet,
    communityMessagePollViewSet,
    communityMessagePollVoteViewSet,
    communityMessageViewSet,
    directChatViewSet,
    directMessageViewSet,
    directMessagePollOptionViewSet,
    directMessagePollViewSet,
    directMessagePollVoteViewSet,
    friendRequestViewSet,
    oauth_signin,
    resend_oauth_code,
    verify_oauth_code,
    userViewSet,
)

router = DefaultRouter()
router.register(r'users', userViewSet, basename='users')
router.register(r'communities', communityViewSet, basename='communities')
router.register(r'community-messages', communityMessageViewSet, basename='community-messages')
router.register(r'community-message-polls', communityMessagePollViewSet, basename='community-message-polls')
router.register(r'community-message-poll-options', communityMessagePollOptionViewSet, basename='community-message-poll-options')
router.register(r'community-message-poll-votes', communityMessagePollVoteViewSet, basename='community-message-poll-votes')
router.register(r'direct-chats', directChatViewSet, basename='direct-chats')
router.register(r'direct-messages', directMessageViewSet, basename='direct-messages')
router.register(r'direct-message-polls', directMessagePollViewSet, basename='direct-message-polls')
router.register(r'direct-message-poll-options', directMessagePollOptionViewSet, basename='direct-message-poll-options')
router.register(r'direct-message-poll-votes', directMessagePollVoteViewSet, basename='direct-message-poll-votes')
router.register(r'friend-requests', friendRequestViewSet, basename='friend-requests')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/oauth-signin/', oauth_signin),
    path('api/users/verify-oauth-code/', verify_oauth_code),
    path('api/users/resend-oauth-code/', resend_oauth_code),
    path('api/', include(router.urls)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
