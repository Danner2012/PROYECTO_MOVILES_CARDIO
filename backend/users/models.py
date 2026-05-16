import uuid
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin

class Role(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.nombre

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('El email es obligatorio')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        
        # Asignar rol superadmin si existe
        try:
            role = Role.objects.get(nombre='superadmin')
            extra_fields.setdefault('rol', role)
        except Role.DoesNotExist:
            pass

        return self.create_user(email, password, **extra_fields)

class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rol = models.ForeignKey(Role, on_delete=models.PROTECT, related_name='usuarios')
    
    email = models.EmailField(max_length=150, unique=True)
    estado = models.CharField(max_length=20, default='activo')
    
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    objects = UserManager()

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    def __str__(self):
        return self.email

class Perfil(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    usuario = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil')
    
    nombre = models.CharField(max_length=100)
    apellido = models.CharField(max_length=100)
    
    fecha_nacimiento = models.DateField(null=True, blank=True)
    genero = models.CharField(max_length=20, null=True, blank=True)
    
    telefono = models.CharField(max_length=30, null=True, blank=True)
    direccion = models.TextField(null=True, blank=True)
    
    foto = models.ImageField(upload_to='perfiles/', null=True, blank=True)
    
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.nombre} {self.apellido}"
