from django.db import models
from django.core.exceptions import ValidationError
from django.db.models.signals import m2m_changed
from django.dispatch import receiver
from django.utils import timezone

# Create your models here.


class user(models.Model):
	GENDER_CHOICES = [
		("male", "Male"),
		("female", "Female"),
	]

	id = models.AutoField(primary_key=True)
	name = models.CharField(max_length=255)
	email = models.EmailField(max_length=255)
	password = models.CharField(max_length=255)
	gender = models.CharField(max_length=10, choices=GENDER_CHOICES)
	birthday = models.DateField()
	location = models.CharField(max_length=255)
	intrest1 = models.CharField(max_length=100, blank=True)
	intrest2 = models.CharField(max_length=100, blank=True)
	intrest3 = models.CharField(max_length=100, blank=True)
	intrest4 = models.CharField(max_length=100, blank=True)
	friends = models.ManyToManyField("self", blank=True, symmetrical=True)
	communities = models.ManyToManyField("community", blank=True, related_name="members")
	diamonds = models.PositiveIntegerField(default=20)
	level = models.PositiveIntegerField(default=1)
	profilepicture = models.ImageField(upload_to="profile_pictures/", blank=True, null=True)

	def sync_level_from_friends(self):
		# Level is derived from friend count, with 1 as the minimum baseline.
		self.level = max(1, self.friends.count())
		self.save(update_fields=["level"])

	def __str__(self):
		return self.name


class community(models.Model):
	id = models.AutoField(primary_key=True)
	name = models.CharField(max_length=255, unique=True)
	description = models.TextField(blank=True)
	maxParticipants = models.PositiveIntegerField(default=0)
	totalParticipants = models.PositiveIntegerField(default=0)
	communityPicture = models.ImageField(upload_to="community_pictures/", blank=True, null=True)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		constraints = [
			models.CheckConstraint(
				condition=models.Q(totalParticipants__lte=models.F("maxParticipants")),
				name="community_total_lte_max",
			),
		]

	def __str__(self):
		return self.name


class directchat(models.Model):
	id = models.AutoField(primary_key=True)
	user1 = models.ForeignKey(user, on_delete=models.CASCADE, related_name="direct_chats_as_user1")
	user2 = models.ForeignKey(user, on_delete=models.CASCADE, related_name="direct_chats_as_user2")
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	@classmethod
	def ensure_between_users(cls, user_a, user_b):
		if user_a.id == user_b.id:
			raise ValidationError("A user cannot create a direct chat with themselves.")

		first_user, second_user = sorted((user_a, user_b), key=lambda current_user: current_user.id)
		chat, _ = cls.objects.get_or_create(user1=first_user, user2=second_user)
		return chat

	@classmethod
	def ensure_for_user_friends(cls, current_user):
		for friend in current_user.friends.all():
			cls.ensure_between_users(current_user, friend)

	class Meta:
		constraints = [
			models.CheckConstraint(condition=~models.Q(user1=models.F("user2")), name="directchat_distinct_users"),
			models.UniqueConstraint(fields=["user1", "user2"], name="unique_directchat_pair"),
		]

	def clean(self):
		if self.user1_id and self.user2_id and self.user1_id == self.user2_id:
			raise ValidationError("A user cannot create a direct chat with themselves.")

		if self.user1_id and self.user2_id:
			are_friends = user.objects.filter(id=self.user1_id, friends__id=self.user2_id).exists()
			if not are_friends:
				raise ValidationError("Direct chat is allowed only between friends.")

	def save(self, *args, **kwargs):
		# Canonical ordering prevents duplicate chats for the same pair.
		if self.user1_id and self.user2_id and self.user1_id > self.user2_id:
			self.user1_id, self.user2_id = self.user2_id, self.user1_id
		self.full_clean()
		return super().save(*args, **kwargs)

	def __str__(self):
		return f"{self.user1} - {self.user2}"


class directmessage(models.Model):
	id = models.AutoField(primary_key=True)
	chat = models.ForeignKey(directchat, on_delete=models.CASCADE, related_name="messages")
	sender = models.ForeignKey(user, on_delete=models.CASCADE, related_name="sent_direct_messages")
	text = models.TextField(blank=True)
	image = models.ImageField(upload_to="direct_chat/images/", blank=True, null=True)
	video = models.FileField(upload_to="direct_chat/videos/", blank=True, null=True)
	voiceRecording = models.FileField(upload_to="direct_chat/voice/", blank=True, null=True)
	hasPoll = models.BooleanField(default=False)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ["created_at"]

	def clean(self):
		if self.chat_id and self.sender_id:
			if self.sender_id not in (self.chat.user1_id, self.chat.user2_id):
				raise ValidationError("Sender must be one of the chat participants.")

		has_content = (
			bool(self.text and self.text.strip())
			or bool(self.image)
			or bool(self.video)
			or bool(self.voiceRecording)
			or bool(self.hasPoll)
		)
		if not has_content:
			raise ValidationError("Message must include text, image, video, voiceRecording, or a poll.")

	def save(self, *args, **kwargs):
		self.full_clean()
		return super().save(*args, **kwargs)

	def __str__(self):
		return f"Message {self.id} in chat {self.chat_id}"


class friendrequest(models.Model):
	STATUS_PENDING = "pending"
	STATUS_ACCEPTED = "accepted"
	STATUS_REJECTED = "rejected"

	STATUS_CHOICES = [
		(STATUS_PENDING, "Pending"),
		(STATUS_ACCEPTED, "Accepted"),
		(STATUS_REJECTED, "Rejected"),
	]

	id = models.AutoField(primary_key=True)
	requester = models.ForeignKey(user, on_delete=models.CASCADE, related_name="sent_friend_requests")
	receiver = models.ForeignKey(user, on_delete=models.CASCADE, related_name="received_friend_requests")
	status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		constraints = [
			models.CheckConstraint(condition=~models.Q(requester=models.F("receiver")), name="friendrequest_distinct_users"),
			models.UniqueConstraint(fields=["requester", "receiver"], name="unique_friendrequest_direction"),
		]

	def clean(self):
		if self.requester_id and self.receiver_id and self.requester_id == self.receiver_id:
			raise ValidationError("A user cannot send a friend request to themselves.")

		if self.requester_id and self.receiver_id:
			already_friends = user.objects.filter(id=self.requester_id, friends__id=self.receiver_id).exists()
			if already_friends:
				raise ValidationError("Users are already friends.")

			reverse_pending_exists = friendrequest.objects.filter(
				requester_id=self.receiver_id,
				receiver_id=self.requester_id,
				status=self.STATUS_PENDING,
			).exclude(id=self.id).exists()
			if reverse_pending_exists and self.status == self.STATUS_PENDING:
				raise ValidationError("A pending friend request already exists in the opposite direction.")

	def save(self, *args, **kwargs):
		self.full_clean()
		return super().save(*args, **kwargs)

	def __str__(self):
		return f"{self.requester} -> {self.receiver} ({self.status})"


class oauthverificationcode(models.Model):
	PROVIDER_GOOGLE = "google"
	PROVIDER_CHOICES = [
		(PROVIDER_GOOGLE, "Google"),
	]

	id = models.AutoField(primary_key=True)
	email = models.EmailField(max_length=255)
	provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES, default=PROVIDER_GOOGLE)
	provider_user_id = models.CharField(max_length=255, blank=True)
	code = models.CharField(max_length=6)
	expires_at = models.DateTimeField()
	is_used = models.BooleanField(default=False)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		constraints = [
			models.UniqueConstraint(fields=["email", "provider"], name="unique_oauth_code_per_email_provider"),
		]

	def has_expired(self):
		return timezone.now() >= self.expires_at

	def __str__(self):
		return f"{self.email} ({self.provider})"


class directmessagepoll(models.Model):
	id = models.AutoField(primary_key=True)
	message = models.OneToOneField(directmessage, on_delete=models.CASCADE, related_name="poll")
	question = models.CharField(max_length=255)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self):
		return self.question


class directmessagepolloption(models.Model):
	id = models.AutoField(primary_key=True)
	poll = models.ForeignKey(directmessagepoll, on_delete=models.CASCADE, related_name="options")
	optionName = models.CharField(max_length=255)
	voteCount = models.PositiveIntegerField(default=0)

	def __str__(self):
		return self.optionName


class directmessagepollvote(models.Model):
	id = models.AutoField(primary_key=True)
	option = models.ForeignKey(directmessagepolloption, on_delete=models.CASCADE, related_name="votes")
	voter = models.ForeignKey(user, on_delete=models.CASCADE, related_name="direct_poll_votes")
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		constraints = [
			models.UniqueConstraint(fields=["option", "voter"], name="unique_vote_per_option_per_user"),
		]

	def clean(self):
		if self.option_id and self.voter_id:
			chat = self.option.poll.message.chat
			if self.voter_id not in (chat.user1_id, chat.user2_id):
				raise ValidationError("Voter must be one of the chat participants.")

			already_voted_in_poll = directmessagepollvote.objects.filter(
				option__poll=self.option.poll,
				voter_id=self.voter_id,
			).exclude(id=self.id).exists()
			if already_voted_in_poll:
				raise ValidationError("User has already voted in this poll.")

	def save(self, *args, **kwargs):
		self.full_clean()
		result = super().save(*args, **kwargs)
		self.option.voteCount = self.option.votes.count()
		self.option.save(update_fields=["voteCount"])
		return result

	def delete(self, *args, **kwargs):
		option = self.option
		result = super().delete(*args, **kwargs)
		option.voteCount = option.votes.count()
		option.save(update_fields=["voteCount"])
		return result

	def __str__(self):
		return f"Vote by {self.voter_id} on option {self.option_id}"


class communitymessage(models.Model):
	id = models.AutoField(primary_key=True)
	community = models.ForeignKey(community, on_delete=models.CASCADE, related_name="messages")
	sender = models.ForeignKey(user, on_delete=models.CASCADE, related_name="sent_community_messages")
	text = models.TextField(blank=True)
	image = models.ImageField(upload_to="community_chat/images/", blank=True, null=True)
	video = models.FileField(upload_to="community_chat/videos/", blank=True, null=True)
	voiceRecording = models.FileField(upload_to="community_chat/voice/", blank=True, null=True)
	hasPoll = models.BooleanField(default=False)
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ["created_at"]

	def clean(self):
		if self.community_id and self.sender_id:
			is_member = self.community.members.filter(id=self.sender_id).exists()
			if not is_member:
				raise ValidationError("Sender must be a member of the community.")

		has_content = (
			bool(self.text and self.text.strip())
			or bool(self.image)
			or bool(self.video)
			or bool(self.voiceRecording)
			or bool(self.hasPoll)
		)
		if not has_content:
			raise ValidationError("Message must include text, image, video, voiceRecording, or a poll.")

	def save(self, *args, **kwargs):
		self.full_clean()
		return super().save(*args, **kwargs)

	def __str__(self):
		return f"Community message {self.id} in community {self.community_id}"


class communitymessagepoll(models.Model):
	id = models.AutoField(primary_key=True)
	message = models.OneToOneField(communitymessage, on_delete=models.CASCADE, related_name="poll")
	question = models.CharField(max_length=255)
	created_at = models.DateTimeField(auto_now_add=True)

	def __str__(self):
		return self.question


class communitymessagepolloption(models.Model):
	id = models.AutoField(primary_key=True)
	poll = models.ForeignKey(communitymessagepoll, on_delete=models.CASCADE, related_name="options")
	optionName = models.CharField(max_length=255)
	voteCount = models.PositiveIntegerField(default=0)

	def __str__(self):
		return self.optionName


class communitymessagepollvote(models.Model):
	id = models.AutoField(primary_key=True)
	option = models.ForeignKey(communitymessagepolloption, on_delete=models.CASCADE, related_name="votes")
	voter = models.ForeignKey(user, on_delete=models.CASCADE, related_name="community_poll_votes")
	created_at = models.DateTimeField(auto_now_add=True)

	class Meta:
		constraints = [
			models.UniqueConstraint(fields=["option", "voter"], name="unique_community_vote_per_option_per_user"),
		]

	def clean(self):
		if self.option_id and self.voter_id:
			community_obj = self.option.poll.message.community
			is_member = community_obj.members.filter(id=self.voter_id).exists()
			if not is_member:
				raise ValidationError("Voter must be a member of the community.")

			already_voted_in_poll = communitymessagepollvote.objects.filter(
				option__poll=self.option.poll,
				voter_id=self.voter_id,
			).exclude(id=self.id).exists()
			if already_voted_in_poll:
				raise ValidationError("User has already voted in this poll.")

	def save(self, *args, **kwargs):
		self.full_clean()
		result = super().save(*args, **kwargs)
		self.option.voteCount = self.option.votes.count()
		self.option.save(update_fields=["voteCount"])
		return result

	def delete(self, *args, **kwargs):
		option = self.option
		result = super().delete(*args, **kwargs)
		option.voteCount = option.votes.count()
		option.save(update_fields=["voteCount"])
		return result

	def __str__(self):
		return f"Community vote by {self.voter_id} on option {self.option_id}"


@receiver(m2m_changed, sender=user.friends.through)
def sync_user_level_on_friends_change(sender, instance, action, reverse, pk_set, **kwargs):
	if action == "pre_clear":
		instance._friends_before_clear = list(instance.friends.values_list("id", flat=True))
		return

	if action not in {"post_add", "post_remove", "post_clear"}:
		return

	instance.sync_level_from_friends()

	if action == "post_clear":
		cleared_ids = getattr(instance, "_friends_before_clear", [])
		for related_user in user.objects.filter(pk__in=cleared_ids):
			related_user.sync_level_from_friends()
		if hasattr(instance, "_friends_before_clear"):
			delattr(instance, "_friends_before_clear")
		return

	if pk_set:
		for related_user in user.objects.filter(pk__in=pk_set):
			related_user.sync_level_from_friends()
