from rest_framework import serializers
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


class userSerializer(serializers.ModelSerializer):
	class Meta:
		model = user
		fields = [
			"id",
			"name",
			"email",
			"password",
			"gender",
			"birthday",
			"location",
			"intrest1",
			"intrest2",
			"intrest3",
			"intrest4",
			"friends",
			"communities",
			"diamonds",
			"profilepicture",
		]


class communitySerializer(serializers.ModelSerializer):
	def validate(self, attrs):
		max_participants = attrs.get(
			"maxParticipants",
			self.instance.maxParticipants if self.instance else 0,
		)
		total_participants = attrs.get(
			"totalParticipants",
			self.instance.totalParticipants if self.instance else 0,
		)

		if total_participants > max_participants:
			raise serializers.ValidationError(
				{"totalParticipants": "totalParticipants cannot be greater than maxParticipants."}
			)

		return attrs

	class Meta:
		model = community
		fields = [
			"id",
			"name",
			"description",
			"maxParticipants",
			"totalParticipants",
			"communityPicture",
			"created_at",
			"members",
		]


class directChatSerializer(serializers.ModelSerializer):
	def validate(self, attrs):
		user1_id = attrs.get("user1", self.instance.user1 if self.instance else None)
		user2_id = attrs.get("user2", self.instance.user2 if self.instance else None)

		user1_id = user1_id.id if hasattr(user1_id, "id") else user1_id
		user2_id = user2_id.id if hasattr(user2_id, "id") else user2_id

		if user1_id and user2_id and user1_id == user2_id:
			raise serializers.ValidationError("A user cannot create a direct chat with themselves.")

		if user1_id and user2_id:
			are_friends = user.objects.filter(id=user1_id, friends__id=user2_id).exists()
			if not are_friends:
				raise serializers.ValidationError("Direct chat is allowed only between friends.")

		return attrs

	def create(self, validated_data):
		user1_obj = validated_data["user1"]
		user2_obj = validated_data["user2"]
		if user1_obj.id > user2_obj.id:
			user1_obj, user2_obj = user2_obj, user1_obj
		chat, _ = directchat.objects.get_or_create(user1=user1_obj, user2=user2_obj)
		return chat

	class Meta:
		model = directchat
		fields = ["id", "user1", "user2", "created_at", "updated_at"]


class directMessageSerializer(serializers.ModelSerializer):
	pollQuestion = serializers.CharField(write_only=True, required=False, allow_blank=False)
	pollOptions = serializers.ListField(
		child=serializers.CharField(allow_blank=False),
		write_only=True,
		required=False,
	)
	poll = serializers.SerializerMethodField(read_only=True)

	def get_poll(self, obj):
		if not hasattr(obj, "poll"):
			return None
		return directMessagePollSerializer(obj.poll).data

	def validate(self, attrs):
		poll_question = attrs.get("pollQuestion")
		poll_options = attrs.get("pollOptions")

		if poll_question and (not poll_options or len(poll_options) < 2):
			raise serializers.ValidationError("A poll must include at least 2 options.")
		if poll_options and not poll_question:
			raise serializers.ValidationError("pollQuestion is required when pollOptions are provided.")

		chat_obj = attrs.get("chat", self.instance.chat if self.instance else None)
		sender_obj = attrs.get("sender", self.instance.sender if self.instance else None)

		if chat_obj and sender_obj:
			if sender_obj.id not in (chat_obj.user1_id, chat_obj.user2_id):
				raise serializers.ValidationError("Sender must be one of the chat participants.")

		text_value = attrs.get("text", self.instance.text if self.instance else "")
		image_value = attrs.get("image", self.instance.image if self.instance else None)
		video_value = attrs.get("video", self.instance.video if self.instance else None)
		voice_value = attrs.get("voiceRecording", self.instance.voiceRecording if self.instance else None)
		has_poll = bool(poll_question and poll_options)

		has_content = bool(text_value and str(text_value).strip()) or bool(image_value) or bool(video_value) or bool(voice_value) or has_poll
		if not has_content:
			raise serializers.ValidationError("Message must include text, image, video, voiceRecording, or a poll.")

		return attrs

	def create(self, validated_data):
		poll_question = validated_data.pop("pollQuestion", None)
		poll_options = validated_data.pop("pollOptions", [])

		if poll_question and poll_options:
			validated_data["hasPoll"] = True

		message = super().create(validated_data)

		if poll_question and poll_options:
			poll = directmessagepoll.objects.create(message=message, question=poll_question)
			for option_name in poll_options:
				directmessagepolloption.objects.create(poll=poll, optionName=option_name)

		return message

	class Meta:
		model = directmessage
		fields = [
			"id",
			"chat",
			"sender",
			"text",
			"image",
			"video",
			"voiceRecording",
			"hasPoll",
			"pollQuestion",
			"pollOptions",
			"poll",
			"created_at",
		]
		read_only_fields = ["created_at", "hasPoll"]


class directMessagePollVoteSerializer(serializers.ModelSerializer):
	voterName = serializers.CharField(source="voter.name", read_only=True)
	voterProfile = serializers.ImageField(source="voter.profilepicture", read_only=True)

	class Meta:
		model = directmessagepollvote
		fields = ["id", "option", "voter", "voterName", "voterProfile", "created_at"]
		read_only_fields = ["created_at"]


class directMessagePollOptionSerializer(serializers.ModelSerializer):
	votes = directMessagePollVoteSerializer(many=True, read_only=True)

	class Meta:
		model = directmessagepolloption
		fields = ["id", "poll", "optionName", "voteCount", "votes"]
		read_only_fields = ["voteCount"]


class directMessagePollSerializer(serializers.ModelSerializer):
	options = directMessagePollOptionSerializer(many=True, read_only=True)

	class Meta:
		model = directmessagepoll
		fields = ["id", "message", "question", "created_at", "options"]
		read_only_fields = ["created_at"]


class communityMessagePollVoteSerializer(serializers.ModelSerializer):
	voterName = serializers.CharField(source="voter.name", read_only=True)
	voterProfile = serializers.ImageField(source="voter.profilepicture", read_only=True)

	class Meta:
		model = communitymessagepollvote
		fields = ["id", "option", "voter", "voterName", "voterProfile", "created_at"]
		read_only_fields = ["created_at"]


class communityMessagePollOptionSerializer(serializers.ModelSerializer):
	votes = communityMessagePollVoteSerializer(many=True, read_only=True)

	class Meta:
		model = communitymessagepolloption
		fields = ["id", "poll", "optionName", "voteCount", "votes"]
		read_only_fields = ["voteCount"]


class communityMessagePollSerializer(serializers.ModelSerializer):
	options = communityMessagePollOptionSerializer(many=True, read_only=True)

	class Meta:
		model = communitymessagepoll
		fields = ["id", "message", "question", "created_at", "options"]
		read_only_fields = ["created_at"]


class communityMessageSerializer(serializers.ModelSerializer):
	pollQuestion = serializers.CharField(write_only=True, required=False, allow_blank=False)
	pollOptions = serializers.ListField(
		child=serializers.CharField(allow_blank=False),
		write_only=True,
		required=False,
	)
	poll = serializers.SerializerMethodField(read_only=True)

	def get_poll(self, obj):
		if not hasattr(obj, "poll"):
			return None
		return communityMessagePollSerializer(obj.poll).data

	def validate(self, attrs):
		poll_question = attrs.get("pollQuestion")
		poll_options = attrs.get("pollOptions")

		if poll_question and (not poll_options or len(poll_options) < 2):
			raise serializers.ValidationError("A poll must include at least 2 options.")
		if poll_options and not poll_question:
			raise serializers.ValidationError("pollQuestion is required when pollOptions are provided.")

		community_obj = attrs.get("community", self.instance.community if self.instance else None)
		sender_obj = attrs.get("sender", self.instance.sender if self.instance else None)

		if community_obj and sender_obj:
			if not community_obj.members.filter(id=sender_obj.id).exists():
				raise serializers.ValidationError("Sender must be a member of the community.")

		text_value = attrs.get("text", self.instance.text if self.instance else "")
		image_value = attrs.get("image", self.instance.image if self.instance else None)
		video_value = attrs.get("video", self.instance.video if self.instance else None)
		voice_value = attrs.get("voiceRecording", self.instance.voiceRecording if self.instance else None)
		has_poll = bool(poll_question and poll_options)

		has_content = bool(text_value and str(text_value).strip()) or bool(image_value) or bool(video_value) or bool(voice_value) or has_poll
		if not has_content:
			raise serializers.ValidationError("Message must include text, image, video, voiceRecording, or a poll.")

		return attrs

	def create(self, validated_data):
		poll_question = validated_data.pop("pollQuestion", None)
		poll_options = validated_data.pop("pollOptions", [])

		if poll_question and poll_options:
			validated_data["hasPoll"] = True

		message = super().create(validated_data)

		if poll_question and poll_options:
			poll = communitymessagepoll.objects.create(message=message, question=poll_question)
			for option_name in poll_options:
				communitymessagepolloption.objects.create(poll=poll, optionName=option_name)

		return message

	class Meta:
		model = communitymessage
		fields = [
			"id",
			"community",
			"sender",
			"text",
			"image",
			"video",
			"voiceRecording",
			"hasPoll",
			"pollQuestion",
			"pollOptions",
			"poll",
			"created_at",
		]
		read_only_fields = ["created_at", "hasPoll"]


class friendRequestSerializer(serializers.ModelSerializer):
	def validate(self, attrs):
		requester_obj = attrs.get("requester", self.instance.requester if self.instance else None)
		receiver_obj = attrs.get("receiver", self.instance.receiver if self.instance else None)
		new_status = attrs.get("status", self.instance.status if self.instance else friendrequest.STATUS_PENDING)

		if requester_obj and receiver_obj:
			if requester_obj.id == receiver_obj.id:
				raise serializers.ValidationError("A user cannot send a friend request to themselves.")

			already_friends = user.objects.filter(id=requester_obj.id, friends__id=receiver_obj.id).exists()
			if already_friends:
				raise serializers.ValidationError("Users are already friends.")

			reverse_pending_exists = friendrequest.objects.filter(
				requester=receiver_obj,
				receiver=requester_obj,
				status=friendrequest.STATUS_PENDING,
			).exclude(id=self.instance.id if self.instance else None).exists()

			if reverse_pending_exists and new_status == friendrequest.STATUS_PENDING:
				raise serializers.ValidationError("A pending friend request already exists in the opposite direction.")

		if self.instance and self.instance.status != friendrequest.STATUS_PENDING and "status" in attrs:
			raise serializers.ValidationError("Only pending requests can be updated.")

		return attrs

	def update(self, instance, validated_data):
		instance = super().update(instance, validated_data)
		if instance.status == friendrequest.STATUS_ACCEPTED:
			instance.requester.friends.add(instance.receiver)
		return instance

	class Meta:
		model = friendrequest
		fields = ["id", "requester", "receiver", "status", "created_at", "updated_at"]
		read_only_fields = ["created_at", "updated_at"]
