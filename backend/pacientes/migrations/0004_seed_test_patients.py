from django.db import migrations

def seed_test_patients(apps, schema_editor):
    User = apps.get_model('users', 'User')
    Paciente = apps.get_model('pacientes', 'Paciente')

    try:
        doctor = User.objects.get(email='doctor@cardio.com')
        paciente_user = User.objects.get(email='paciente@cardio.com')
    except User.DoesNotExist:
        # Si los usuarios no existen, no podemos crear el registro de paciente
        return

    # Crear registro en la tabla Paciente si no existe
    if not Paciente.objects.filter(usuario=paciente_user).exists():
        Paciente.objects.create(
            usuario=paciente_user,
            doctor=doctor,
            edad=45,
            sexo='Femenino',
            peso_inicial=65.5,
            talla_inicial=1.65
        )

def remove_test_patients(apps, schema_editor):
    Paciente = apps.get_model('pacientes', 'Paciente')
    # Borrar por el email del usuario asociado
    Paciente.objects.filter(usuario__email='paciente@cardio.com').delete()

class Migration(migrations.Migration):

    dependencies = [
        ('pacientes', '0003_alter_paciente_doctor'),
        ('users', '0004_seed_test_users'), # Dependencia crucial para asegurar que los usuarios existan
    ]

    operations = [
        migrations.RunPython(seed_test_patients, remove_test_patients),
    ]
