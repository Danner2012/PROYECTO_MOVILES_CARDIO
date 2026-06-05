from django.db import migrations
from django.contrib.auth.hashers import make_password

def seed_test_users(apps, schema_editor):
    User = apps.get_model('users', 'User')
    Role = apps.get_model('users', 'Role')
    Perfil = apps.get_model('users', 'Perfil')

    try:
        rol_admin = Role.objects.get(nombre='administrador')
        rol_doctor = Role.objects.get(nombre='doctor')
        rol_paciente = Role.objects.get(nombre='paciente')
    except Role.DoesNotExist:
        # Si no existen los roles, no podemos crear los usuarios
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

    # Crear Doctor
    doctor_email = 'doctor@cardio.com'
    if not User.objects.filter(email=doctor_email).exists():
        doctor = User.objects.create(
            email=doctor_email,
            password=make_password('pass123'),
            rol=rol_doctor,
            is_active=True,
            estado='activo'
        )
        Perfil.objects.create(
            usuario=doctor,
            nombre='Juan',
            apellido='Pérez',
            telefono='555-1234',
            genero='Masculino'
        )

    # Crear Paciente (Usuario)
    paciente_email = 'paciente@cardio.com'
    if not User.objects.filter(email=paciente_email).exists():
        paciente = User.objects.create(
            email=paciente_email,
            password=make_password('pass123'),
            rol=rol_paciente,
            is_active=True,
            estado='activo'
        )
        Perfil.objects.create(
            usuario=paciente,
            nombre='María',
            apellido='García',
            telefono='555-5678',
            genero='Femenino'
        )

def remove_test_users(apps, schema_editor):
    User = apps.get_model('users', 'User')
    emails = ['admin@cardio.com', 'doctor@cardio.com', 'paciente@cardio.com']
    User.objects.filter(email__in=emails).delete()

class Migration(migrations.Migration):

    dependencies = [
        ('users', '0003_remove_perfil_foto_url_perfil_foto'),
    ]

    operations = [
        migrations.RunPython(seed_test_users, remove_test_users),
    ]
