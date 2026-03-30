from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0007_directchat_directmessage_friendrequest"),
    ]

    operations = [
        migrations.AddField(
            model_name="directmessage",
            name="hasPoll",
            field=models.BooleanField(default=False),
        ),
        migrations.CreateModel(
            name="directmessagepoll",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("question", models.CharField(max_length=255)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "message",
                    models.OneToOneField(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="poll",
                        to="backend.directmessage",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="directmessagepolloption",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("optionName", models.CharField(max_length=255)),
                ("voteCount", models.PositiveIntegerField(default=0)),
                (
                    "poll",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="options",
                        to="backend.directmessagepoll",
                    ),
                ),
            ],
        ),
        migrations.CreateModel(
            name="directmessagepollvote",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "option",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="votes",
                        to="backend.directmessagepolloption",
                    ),
                ),
                (
                    "voter",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="direct_poll_votes",
                        to="backend.user",
                    ),
                ),
            ],
        ),
        migrations.AddConstraint(
            model_name="directmessagepolloption",
            constraint=models.UniqueConstraint(fields=("poll", "optionName"), name="unique_poll_option_name"),
        ),
        migrations.AddConstraint(
            model_name="directmessagepollvote",
            constraint=models.UniqueConstraint(fields=("option", "voter"), name="unique_vote_per_option_per_user"),
        ),
    ]
