from django.db import migrations
from django.contrib.auth.hashers import make_password

def seed_admin_user(apps, schema_editor):
    User = apps.get_model('users', 'User')
    Role = apps.get_model('users', 'Role')
    Perfil = apps.get_model('users', 'Perfil')

    try:
        rol_admin = Role.objects.get(nombre='administrador')
    except Role.DoesNotExist:
        # Si el rol no existe, no podemos crear el usuario
        return

    # Crear Administrador
    admin_email = 'admin@cardio.com'
    if not User.objects.filter(email=admin_email).exists():
        admin = User.objects.create(
            email=admin_email,
            password=make_password('admin123'),
            rol=rol_admin,
            is_active=True,
            estado='activo',
            is_staff=True
        )
        Perfil.objects.create(
            usuario=admin,
            nombre='Administrador',
            apellido='Sistema',
            telefono='555-9999',
            genero='Otro'
        )

def remove_admin_user(apps, schema_editor):
    User = apps.get_model('users', 'User')
    User.objects.filter(email='admin@cardio.com').delete()

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0004_seed_test_users'),
    ]

    operations = [
        migrations.RunPython(seed_admin_user, remove_admin_user),
    ]
