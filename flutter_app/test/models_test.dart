import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:only_eyes_360/core/utils/formatters.dart';
import 'package:only_eyes_360/models/client_model.dart';
import 'package:only_eyes_360/models/clinic_models.dart';
import 'package:only_eyes_360/models/prescription_model.dart';
import 'package:only_eyes_360/models/product_model.dart';
import 'package:only_eyes_360/models/sale_model.dart';
import 'package:only_eyes_360/models/supplier_model.dart';
import 'package:only_eyes_360/models/user_model.dart';
import 'package:only_eyes_360/screens/admin/appointments_screen.dart';

void main() {
  group('ONLY EYES 360 - Modelos y Contratos de Datos', () {
    test('UserModel parsea correctamente el payload de FastAPI', () {
      final json = {
        'id': 1,
        'nombre': 'Administrador Principal',
        'usuario': 'admin',
        'rol': 'admin',
        'activo': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 1);
      expect(user.nombre, 'Administrador Principal');
      expect(user.usuario, 'admin');
      expect(user.rol, 'admin');
      expect(user.activo, true);
    });

    test('ClientModel concatena nombres y apellidos', () {
      final client = ClientModel(
        id: 10,
        nombres: 'Carlos',
        apellidos: 'Gómez',
        telefono: '8095551234',
        correo: 'carlos@ejemplo.com',
      );

      expect(client.nombreCompleto, 'Carlos Gómez');
    });

    test('PrescriptionModel maneja correctamente datos optométricos OD y OI', () {
      final json = {
        'id': 5,
        'paciente_id': 2,
        'fecha_receta': '2026-11-04',
        'od_esfera': -2.25,
        'od_cilindro': -0.75,
        'od_eje': 90,
        'oi_esfera': -1.50,
        'oi_cilindro': -0.50,
        'oi_eje': 180,
        'adicion': 1.75,
        'distancia_pupilar': 62.5,
        'diagnostico': 'Miopía y astigmatismo miópico',
        'profesional': 'Dr. Alejandro Peña',
      };

      final rx = PrescriptionModel.fromJson(json);

      expect(rx.odEsfera, -2.25);
      expect(rx.odEje, 90);
      expect(rx.oiEsfera, -1.50);
      expect(rx.oiEje, 180);
      expect(rx.adicion, 1.75);
      expect(rx.distanciaPupilar, 62.5);
    });

    test('ProductModel detecta correctamente la alerta de stock bajo', () {
      final normalProduct = ProductModel(
        id: 1,
        codigo: 'MONT-001',
        nombre: 'Montura Ray-Ban',
        categoria: 'montura',
        precioCompra: 3000.0,
        precioVenta: 5500.0,
        stockActual: 10,
        stockMinimo: 5,
        itbisRate: 0.16,
      );

      final lowStockProduct = ProductModel(
        id: 2,
        codigo: 'MONT-002',
        nombre: 'Montura Acetato',
        categoria: 'montura',
        precioCompra: 1500.0,
        precioVenta: 3200.0,
        stockActual: 3,
        stockMinimo: 5,
      );

      expect(normalProduct.isLowStock, false);
      expect(normalProduct.itbisRate, 0.16);
      expect(lowStockProduct.isLowStock, true);
    });

    test('SupplierModel serializa y deserializa sin perder campos', () {
      final json = {
        'id': 1,
        'nombre': 'Laboratorio Óptico Nacional',
        'rnc': '132456789',
        'contacto': 'Marcos Ruiz',
        'telefono': '8095559988',
        'correo': 'ventas@optilab.com',
        'activo': true,
      };

      final supplier = SupplierModel.fromJson(json);
      expect(supplier.nombre, 'Laboratorio Óptico Nacional');
      expect(supplier.rnc, '132456789');
    });

    test('SaleModel parsea correctamente contratos de FastAPI de Codex', () {
      final json = {
        'id': 101,
        'numero': 'FAC-2026-0101',
        'cliente_id': 3,
        'subtotal': 5000.0,
        'descuento': 500.0,
        'itbis': 810.0,
        'total': 5310.0,
        'monto_pagado': 3000.0,
        'saldo_pendiente': 2310.0,
        'estado': 'completada',
        'estado_pago': 'parcial',
        'detalles': [
          {
            'id': 1,
            'producto_id': 4,
            'cantidad': 1,
            'precio_unitario': 5000.0,
            'subtotal': 5000.0,
          }
        ],
      };

      final sale = SaleModel.fromJson(json);
      expect(sale.id, 101);
      expect(sale.numeroFactura, 'FAC-2026-0101');
      expect(sale.total, 5310.0);
      expect(sale.balancePendiente, 2310.0);
      expect(sale.isPaid, false);
      expect(sale.isPartial, true);
    });

    test('AppointmentModel y LabOrderModel parsean campos clínicos correctamente', () {
      final apptJson = {
        'id': 15,
        'paciente_id': 7,
        'nombres': 'Lucía',
        'apellidos': 'Méndez',
        'fecha_hora': '2026-11-06T10:00:00',
        'motivo': 'Refracción Anual',
        'estado': 'confirmada',
        'profesional': 'Dra. Castillo',
      };

      final appt = AppointmentModel.fromJson(apptJson);
      expect(appt.id, 15);
      expect(appt.pacienteNombre, 'Lucía Méndez');
      expect(appt.estado, 'confirmada');

      final labJson = {
        'id': 30,
        'cliente_id': 7,
        'tipo_montura': 'Metálica Ovalada',
        'tipo_cristal': 'Progresivo Digital AR',
        'laboratorio': 'MegaLab Santo Domingo',
        'estado': 'en_laboratorio',
      };

      final labOrder = LabOrderModel.fromJson(labJson);
      expect(labOrder.id, 30);
      expect(labOrder.tipoCristal, 'Progresivo Digital AR');
      expect(labOrder.estado, 'en_laboratorio');
    });

    test('Formatters oftalmológicos dan formato adecuado a dioptrías y moneda', () {
      expect(Formatters.formatDiopter(1.5), '+1.50 D');
      expect(Formatters.formatDiopter(-2.25), '-2.25 D');
      expect(Formatters.formatDiopter(0), 'Plano');
      expect(Formatters.formatDiopter(null), '-');
      expect(Formatters.formatAxis(90), '90°');
      expect(Formatters.formatPd(63), '63.0 mm');
      expect(Formatters.formatCurrency(5500), 'RD\$5,500.00');
      expect(Formatters.formatCurrency(12500.50), 'RD\$12,500.50');
      expect(Formatters.formatCurrency(1000000), 'RD\$1,000,000.00');
    });

    test('La cita enviada al backend siempre incluye zona horaria', () {
      final iso = appointmentDateTimeIso(
        DateTime(2030, 1, 2),
        const TimeOfDay(hour: 9, minute: 30),
      );
      expect(iso, matches(RegExp(r'^2030-01-02T09:30:00[+-]\d{2}:\d{2}$')));
    });
  });
}
