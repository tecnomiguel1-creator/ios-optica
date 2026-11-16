# Cómo probar Caja diaria y cuadre

Archivos modificados: `backend/app/commerce.py`,
`backend/tests/cash_register_acceptance.py`,
`flutter_app/lib/screens/sales/pos_screen.dart`,
`flutter_app/lib/screens/admin/cash_register_screen.dart` y
`flutter_app/lib/state/app_state.dart`.

1. Confirma en el login que el backend está en línea y que la base es
   `onlyeyes360_test`.
2. Abre caja con RD$2,000.00.
3. Registra una venta de RD$1,000.00: RD$600.00 en efectivo y RD$400.00 con
   tarjeta. La gaveta esperada debe ser RD$2,600.00.
4. Registra un egreso de RD$100.00 con motivo. El esperado pasa a RD$2,500.00.
5. Cierra declarando RD$2,450.00 y un motivo: la diferencia es -RD$50.00.
6. Vuelve a abrir Caja diaria para comprobar que el turno ya no está abierto.
   El administrador puede consultar el historial mediante la API de caja.

Prueba automatizada: desde `backend`, ejecutar
`..\.venv\Scripts\python.exe tests\cash_register_acceptance.py`.
La prueba usa nombres ficticios, exige `onlyeyes360_test` y borra sus datos.
# Actualización: apertura manual y continuidad del turno

1. Inicie sesión sin turno activo: debe verse **Caja cerrada** y el botón
   **Abrir caja**.
2. Pulse el botón, indique el fondo (incluido RD$0.00 si corresponde) y
   confirme. Un cierre de la aplicación no cierra el turno.
3. Al volver a iniciar sesión debe verse **Continuar turno** con la apertura y
   el fondo original.
4. Cierre el turno y vuelva a entrar: debe regresar a **Caja cerrada**. El
   turno cerrado permanece en el historial.

