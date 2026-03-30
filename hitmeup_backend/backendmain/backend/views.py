from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
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


class communityViewSet(viewsets.ModelViewSet):
	queryset = community.objects.all()
	serializer_class = communitySerializer


class communityMessageViewSet(viewsets.ModelViewSet):
	queryset = communitymessage.objects.select_related("community", "sender").all()
	serializer_class = communityMessageSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		community_id = self.request.query_params.get("community")
		if community_id:
			queryset = queryset.filter(community_id=community_id)
		return queryset


class directChatViewSet(viewsets.ModelViewSet):
	queryset = directchat.objects.all()
	serializer_class = directChatSerializer

	def get_queryset(self):
		queryset = super().get_queryset()
		user_id = self.request.query_params.get("user")
		if user_id:
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
