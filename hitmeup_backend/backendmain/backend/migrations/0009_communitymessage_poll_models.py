from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0008_directmessage_poll_models"),
    ]

    operations = [
        migrations.CreateModel(
            name="communitymessage",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("text", models.TextField(blank=True)),
                ("image", models.ImageField(blank=True, null=True, upload_to="community_chat/images/")),
                ("video", models.FileField(blank=True, null=True, upload_to="community_chat/videos/")),
                ("voiceRecording", models.FileField(blank=True, null=True, upload_to="community_chat/voice/")),
                ("hasPoll", models.BooleanField(default=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "community",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="messages",
                        to="backend.community",
                    ),
                ),
                (
                    "sender",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="sent_community_messages",
                        to="backend.user",
                    ),
                ),
            ],
            options={"ordering": ["created_at"]},
        ),
        migrations.CreateModel(
            name="communitymessagepoll",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("question", models.CharField(max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "message",
                    models.OneToOneField(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="poll",
                        to="backend.communitymessage",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="communitymessagepolloption",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("optionName", models.CharField(max_length=255)),
                ("voteCount", models.PositiveIntegerField(default=0)),
                (
                    "poll",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="options",
                        to="backend.communitymessagepoll",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="communitymessagepollvote",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "option",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="votes",
                        to="backend.communitymessagepolloption",
                    ),
                ),
                (
                    "voter",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="community_poll_votes",
                        to="backend.user",
                    ),
                ),
            ],
        ),
        migrations.AddConstraint(
            model_name="communitymessagepolloption",
            constraint=models.UniqueConstraint(fields=("poll", "optionName"), name="unique_community_poll_option_name"),
        ),
        migrations.AddConstraint(
            model_name="communitymessagepollvote",
            constraint=models.UniqueConstraint(fields=("option", "voter"), name="unique_community_vote_per_option_per_user"),
        ),
    ]
