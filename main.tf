/*
Actividad: codificación y comentarios técnicos sobre límites de la automatización declarativa

Nombre: Desireé Siomara Coronel González
Fecha: 06 de junio de 2026

===============================================================================
ESCENARIO SELECCIONADO
======================

Escenario A: Migración de arquitectura de computación desde servidores basados en procesadores Intel/AMD (x86_64) hacia instancias ARM64 utilizando procesadores AWS Graviton.
La organización busca reducir costos operativos y consumo energético así manteniendo el mismo nivel de disponibilidad de los servicios desplegados, sin embargo un cambio de arquitectura implica riesgos de compatibilidad
que deben analizarse antes de una migración a producción.

===============================================================================
STACK DE SOFTWARE ANALIZADO
===========================

Sistema Operativo:
Ubuntu Server 24.04 LTS ARM64

Runtime:
OpenJDK 21 LTS

Framework:
Spring Boot 3.3

Base de Datos:
PostgreSQL 16

Contenedores:
Docker Engine 27

Infraestructura como Código:
Terraform 1.8+

===============================================================================
COMPONENTES AFECTADOS POR LA MIGRACIÓN
======================================

1. Bibliotecas nativas compiladas para x86_64

Aunque Java es multiplataforma, muchas aplicaciones empresariales utilizan bibliotecas nativas desarrolladas en C o C++ para tareas específicas de
alto rendimiento, compresión de datos o acceso a componentes del sistema.
Al migrar desde x86_64 hacia ARM64, dichos binarios dejan de funcionar porque fueron compilados para un conjunto de instrucciones diferente.

Causa raíz:

* Incompatibilidad de binarios ELF.
* Dependencia de instrucciones específicas de x86_64.
* Necesidad de recompilar para ARM64.
* Ausencia de versiones distribuidas para la nueva arquitectura.

---

2. Imágenes Docker incompatibles

No todas las imágenes Docker disponibles en registros públicos poseen versiones ARM64 y muchas imágenes antiguas fueron construidas únicamente
para arquitecturas amd64.

Si una imagen amd64 es desplegada sobre AWS Graviton, Docker puede
presentar errores de ejecución o requerir mecanismos de emulación que
incrementan el consumo de recursos y disminuyen el rendimiento.

Causa raíz:

* Ausencia de manifiestos OCI multiarquitectura.
* Dependencia de imágenes construidas exclusivamente para amd64.
* Diferencias entre arquitecturas de procesador.

---

3. Agentes de monitoreo y seguridad

Las organizaciones suelen utilizar agentes de monitoreo, respaldo y
seguridad que interactúan directamente con el sistema operativo, muchos fabricantes distribuyen únicamente versiones para x86_64 así
generando incompatibilidades durante una migración a ARM64.

Causa raíz:

* Dependencia de módulos nativos.
* Compatibilidad limitada con ARM64.
* Integración directa con componentes del kernel Linux.
* Falta de paquetes compilados para la nueva plataforma.

===============================================================================
¿QUÉ RESUELVE TERRAFORM?
========================

Terraform permite automatizar el aprovisionamiento de infraestructura
compatible con ARM64 utilizando principios de Infraestructura como Código
(IaC).

Mediante Terraform es posible:

* Crear instancias EC2 basadas en AWS Graviton.
* Configurar redes virtuales.
* Configurar grupos de seguridad.
* Administrar almacenamiento persistente.
* Mantener configuraciones reproducibles y versionadas.

Terraform reduce errores humanos y facilita la estandarización de entornos de desarrollo, pruebas y producción.

===============================================================================
¿QUÉ NO PUEDE RESOLVER TERRAFORM?
=================================

Terraform opera exclusivamente a nivel de infraestructura y no inspecciona el comportamiento interno de las aplicaciones.

Por este motivo no puede verificar:

* Compatibilidad de bibliotecas nativas.
* Funcionamiento interno de aplicaciones Java sobre ARM64.
* Compatibilidad de imágenes Docker.
* Compatibilidad de agentes de monitoreo y seguridad.
* Correcta ejecución de dependencias compiladas para otra arquitectura.

Terraform garantiza que la infraestructura exista pero no puede asegurar que el software desplegado funcione correctamente dentro de ella.

===============================================================================
SOLUCIÓN ARQUITECTÓNICA PROPUESTA
=================================

Para cubrir este vacío tecnológico se propone una estrategia compuesta por varias herramientas complementarias.

Terraform:

* Aprovisionamiento de infraestructura.
* Creación de instancias ARM64.
* Configuración de red y almacenamiento.

Packer:

* Construcción de imágenes AMI compatibles con ARM64.
* Validación previa de dependencias.

Ansible:

* Configuración automática del sistema operativo.
* Instalación de paquetes.
* Gestión de configuraciones.

Pipelines CI/CD:

* Compilación automática.
* Pruebas de compatibilidad.
* Pruebas de integración.
* Despliegue automatizado.

Esta arquitectura permite detectar incompatibilidades antes de afectar entornos productivos.

===============================================================================
DECLARACIÓN DE TRANSPARENCIA Y FUENTES
======================================

Para la elaboración de este trabajo se utilizaron herramientas de inteligencia artificial como apoyo para organizar ideas y estructurar el
contenido inicial de modo que las recomendaciones obtenidas fueron contrastadas con documentación oficial de AWS, HashiCorp Terraform, Ubuntu, Docker y
OpenJDK. Adicionalmente, el código Terraform fue validado mediante los comandos terraform init y terraform validate antes de su registro en Git.

Referencias APA

Amazon Web Services. (2025). AWS Graviton Processors.

HashiCorp. (2025). Terraform Documentation.

Canonical Ltd. (2025). Ubuntu Server Documentation.

Docker Inc. (2025). Multi-platform Builds Documentation.

OpenJDK. (2025). OpenJDK Documentation.
*/

terraform {

required_version = ">= 1.8.0"

required_providers {
aws = {
source  = "hashicorp/aws"
version = "~> 5.50"
}
}
}

provider "aws" {
region = var.aws_region
}

variable "aws_region" {
description = "Region AWS"
type        = string
default     = "us-east-1"
}

variable "environment" {
description = "Ambiente"
type        = string
default     = "academico"
}

variable "instance_type" {
description = "Instancia ARM64"
type        = string
default     = "t4g.micro"
}

resource "aws_vpc" "main" {

cidr_block = "10.0.0.0/16"

tags = {
Name = "vpc-arm64"
}
}

resource "aws_security_group" "server_sg" {

name        = "server-sg"
description = "Grupo de seguridad"
vpc_id      = aws_vpc.main.id

ingress {
from_port   = 22
to_port     = 22
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
from_port   = 8000
to_port     = 8000
protocol    = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port   = 0
to_port     = 0
protocol    = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
}

data "aws_ami" "ubuntu_arm64" {

most_recent = true

owners = ["099720109477"]

filter {
name   = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
}

filter {
name   = "architecture"
values = ["arm64"]
}
}

resource "aws_instance" "backend_server" {

ami           = data.aws_ami.ubuntu_arm64.id
instance_type = var.instance_type

vpc_security_group_ids = [
aws_security_group.server_sg.id
]

root_block_device {
volume_size = 30
volume_type = "gp3"
encrypted   = true
}

tags = {
Name         = "backend-arm64"
Architecture = "ARM64"
Processor    = "AWS Graviton"
Environment  = var.environment
}
}

output "instance_id" {
value = aws_instance.backend_server.id
}

output "public_ip" {
value = aws_instance.backend_server.public_ip
}