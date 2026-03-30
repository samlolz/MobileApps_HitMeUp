from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0006_community_total_lte_max_constraint"),
    ]

    operations = [
        migrations.CreateModel(
            name="directchat",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "user1",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="direct_chats_as_user1",
                        to="backend.user",
                    ),
                ),
                (
                    "user2",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="direct_chats_as_user2",
                        to="backend.user",
                    ),
                ),
            ],
            options={},
        ),
        migrations.CreateModel(
            name="directmessage",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("text", models.TextField(blank=True)),
                ("image", models.ImageField(blank=True, null=True, upload_to="direct_chat/images/")),
                ("video", models.FileField(blank=True, null=True, upload_to="direct_chat/videos/")),
                ("voiceRecording", models.FileField(blank=True, null=True, upload_to="direct_chat/voice/")),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "chat",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="messages",
                        to="backend.directchat",
                    ),
                ),
                (
                    "sender",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="sent_direct_messages",
                        to="backend.user",
                    ),
                ),
            ],
            options={"ordering": ["created_at"]},
        ),
        migrations.CreateModel(
            name="friendrequest",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                (
                    "status",
                    models.CharField(
                        choices=[("pending", "Pending"), ("accepted", "Accepted"), ("rejected", "Rejected")],
                        default="pending",
                        max_length=10,
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "receiver",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="received_friend_requests",
                        to="backend.user",
                    ),
                ),
                (
                    "requester",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="sent_friend_requests",
                        to="backend.user",
                    ),
                ),
            ],
        ),
        migrations.AddConstraint(
            model_name="directchat",
            constraint=models.CheckConstraint(check=models.Q(("user1", models.F("user2")), _negated=True), name="directchat_distinct_users"),
        ),
        migrations.AddConstraint(
            model_name="directchat",
            constraint=models.UniqueConstraint(fields=("user1", "user2"), name="unique_directchat_pair"),
        ),
        migrations.AddConstraint(
            model_name="friendrequest",
            constraint=models.CheckConstraint(check=models.Q(("requester", models.F("receiver")), _negated=True), name="friendrequest_distinct_users"),
        ),
        migrations.AddConstraint(
            model_name="friendrequest",
            constraint=models.UniqueConstraint(fields=("requester", "receiver"), name="unique_friendrequest_direction"),
        ),
    ]
