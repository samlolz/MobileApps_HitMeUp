from django.db import migrations


def resync_user_levels(apps, schema_editor):
    User = apps.get_model("backend", "user")

    for u in User.objects.all():
        friend_count = u.friends.count()
        u.level = max(1, friend_count)
        u.save(update_fields=["level"])


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0010_user_level"),
    ]

    operations = [
        migrations.RunPython(resync_user_levels, migrations.RunPython.noop),
    ]
