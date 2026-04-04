from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0013_oauthverificationcode"),
    ]

    operations = [
        migrations.RemoveConstraint(
            model_name="directmessagepolloption",
            name="unique_poll_option_name",
        ),
        migrations.RemoveConstraint(
            model_name="communitymessagepolloption",
            name="unique_community_poll_option_name",
        ),
    ]
