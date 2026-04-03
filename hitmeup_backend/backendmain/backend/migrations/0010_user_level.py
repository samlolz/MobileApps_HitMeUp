from django.db import migrations, models


def backfill_user_level(apps, schema_editor):
    User = apps.get_model("backend", "user")

    for u in User.objects.all():
        friend_count = u.friends.count()
        u.level = max(1, friend_count)
        u.save(update_fields=["level"])


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0009_communitymessage_poll_models"),
    ]

    operations = [
        migrations.AddField(
            model_name="user",
            name="level",
            field=models.PositiveIntegerField(default=1),
        ),
        migrations.RunPython(backfill_user_level, migrations.RunPython.noop),
    ]
