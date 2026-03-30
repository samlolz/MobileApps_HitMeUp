from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0004_community_user_friends_communities"),
    ]

    operations = [
        migrations.AddField(
            model_name="community",
            name="communityPicture",
            field=models.ImageField(blank=True, null=True, upload_to="community_pictures/"),
        ),
        migrations.AddField(
            model_name="community",
            name="maxParticipants",
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name="community",
            name="totalParticipants",
            field=models.PositiveIntegerField(default=0),
        ),
    ]
