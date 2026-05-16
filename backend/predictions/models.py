from django.db import models

class Prediction(models.Model):
    bpm = models.FloatField()
    prediction = models.CharField(max_length=100)
    confidence = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.prediction} ({self.confidence*100:.2f}%) - {self.created_at}"
