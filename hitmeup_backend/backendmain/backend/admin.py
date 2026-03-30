from django.contrib import admin
from .models import user

# Register your models here.


@admin.register(user)
class UserAdmin(admin.ModelAdmin):
	list_display = ("id", "name", "email", "gender", "birthday", "location", "diamonds")
	search_fields = ("name", "email", "location")
