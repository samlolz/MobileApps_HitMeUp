# Generated manually for OAuth verification codes
from django.db import migrations, models
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('backend', '0012_backfill_direct_chats'),
    ]

    operations = [
        migrations.CreateModel(
            name='oauthverificationcode',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('email', models.EmailField(max_length=255)),
                ('provider', models.CharField(choices=[('google', 'Google')], default='google', max_length=20)),
                ('provider_user_id', models.CharField(blank=True, max_length=255)),
                ('code', models.CharField(max_length=6)),
                ('expires_at', models.DateTimeField()),
                ('is_used', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.AddConstraint(
            model_name='oauthverificationcode',
            constraint=models.UniqueConstraint(fields=('email', 'provider'), name='unique_oauth_code_per_email_provider'),
        ),
    ]
