from django.db import migrations


def backfill_direct_chats(apps, schema_editor):
	User = apps.get_model("backend", "user")
	DirectChat = apps.get_model("backend", "directchat")

	for current_user in User.objects.prefetch_related("friends").all():
		for friend in current_user.friends.filter(id__gt=current_user.id):
			first_user, second_user = sorted(
				(current_user, friend), key=lambda current: current.id
			)
			DirectChat.objects.get_or_create(user1=first_user, user2=second_user)


class Migration(migrations.Migration):

	dependencies = [
		("backend", "0011_resync_user_levels"),
	]

	operations = [
		migrations.RunPython(backfill_direct_chats, migrations.RunPython.noop),
	]