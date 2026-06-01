# Relevamientos Digitales CBA

Demo web y mobile para relevamientos digitales en campo de la Provincia de
Córdoba. El proyecto usa un único codebase Flutter y Firebase para hosting,
autenticación y persistencia básica.

## Demo

- Web: https://relevamientos-demo-cba-2026.web.app
- Contraseña común para los perfiles demo: `123`
- Las integraciones externas, incluyendo CiDi, BUC y Rentas, son mocks.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome
```

## Verificar

```bash
flutter analyze
flutter test
flutter build web
```
