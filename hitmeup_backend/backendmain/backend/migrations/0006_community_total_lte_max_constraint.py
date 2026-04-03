from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("backend", "0005_community_maxparticipants_totalparticipants_and_more"),
    ]

    operations = [
        migrations.AddConstraint(
            model_name="community",
            constraint=models.CheckConstraint(
                condition=models.Q(totalParticipants__lte=models.F("maxParticipants")),
                name="community_total_lte_max",
            ),
        ),
    ]
