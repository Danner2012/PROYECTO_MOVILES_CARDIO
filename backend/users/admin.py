from django.contrib import admin
from .models import Role, User, Perfil

@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'id')

@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('email', 'rol', 'estado', 'is_staff', 'fecha_creacion')
    list_filter = ('rol', 'estado', 'is_staff')
    search_fields = ('email',)

@admin.register(Perfil)
class PerfilAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'apellido', 'usuario', 'telefono')
    search_fields = ('nombre', 'apellido', 'usuario__email')
