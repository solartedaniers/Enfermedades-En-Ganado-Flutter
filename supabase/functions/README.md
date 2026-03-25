## Diagnostico con IA real gratis

Esta carpeta deja lista una Edge Function para que Flutter no use la key de la IA directamente.

### Funcion incluida

- `animal-diagnosis`

### Opcion recomendada

Usar Gemini con free tier y dejar el motor local como respaldo.

### Secretos que debes configurar en Supabase

```bash
supabase secrets set GEMINI_API_KEY=tu_key_real
supabase secrets set GEMINI_MODEL=gemini-2.0-flash
```

### Desplegar la funcion

```bash
supabase functions deploy animal-diagnosis
```

### Probar localmente

```bash
supabase functions serve animal-diagnosis
```

### Flujo final

1. La app envia el caso a Supabase.
2. Supabase llama a Gemini.
3. Si Gemini falla o no hay cuota, la app usa el motor local.
