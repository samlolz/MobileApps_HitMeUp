from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0003_alter_user_diamonds"),
    ]

    operations = [
        migrations.CreateModel(
            name="community",
            fields=[
                ("id", models.AutoField(primary_key=True, serialize=False)),
                ("name", models.CharField(max_length=255, unique=True)),
                ("description", models.TextField(blank=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.AddField(
            model_name="user",
            name="communities",
            field=models.ManyToManyField(blank=True, related_name="members", to="backend.community"),
        ),
        migrations.AddField(
            model_name="user",
            name="friends",
            field=models.ManyToManyField(blank=True, to="backend.user"),
        ),
    ]
