# Laboratorio 02: crear buckets S3 con Terraform

En este workshop vas a leer y ejecutar una configuracion de Terraform que crea seis buckets de Amazon S3. Cada bucket recibe un nombre con un sufijo aleatorio y un conjunto de etiquetas.

La idea es recorrer el ciclo de trabajo habitual: preparar el entorno, inicializar Terraform, revisar el plan, aplicar los cambios y, al terminar, eliminar los recursos del laboratorio.

## Objetivos

Al finalizar, podras:

- Identificar la funcion de un provider y de un resource en Terraform.
- Usar `count` para crear varias instancias de un recurso.
- Relacionar recursos mediante `count.index`.
- Generar valores con el provider `random`.
- Revisar un plan antes de modificar recursos en AWS.
- Consultar y destruir recursos administrados por Terraform.

## Antes de comenzar

Necesitas:

- Terraform instalado. Comprueba la instalacion con `terraform version`.
- Una cuenta de AWS y credenciales configuradas para el usuario o rol que ejecutara el laboratorio.
- Permisos suficientes para crear, consultar y eliminar los buckets de S3 del ejercicio.
- Acceso a Internet para que `terraform init` descargue los providers.

Configura las credenciales usando el mecanismo aprobado por tu curso o equipo, por ejemplo AWS IAM Identity Center (SSO), un perfil local de AWS CLI o variables de entorno. **No escribas claves de AWS en los archivos `.tf` ni las subas al repositorio.**

## Estructura del proyecto

```text
terraform-lab02/
|-- README.md
|-- code/
|   |-- bucket.tf
|   |-- provider.tf
|   |-- terraform.tfstate
|   `-- terraform.tfstate.backup
`-- docs/
```

Terraform se ejecuta en el directorio `code/`, donde se encuentran los archivos de configuracion:

- `provider.tf` selecciona la region de AWS (`us-east-1`).
- `bucket.tf` declara los sufijos aleatorios y los buckets de S3.
- `terraform.tfstate` y su respaldo registran asociaciones entre Terraform y recursos administrados. No son archivos de configuracion ni deben editarse manualmente.

> **Atencion con el estado incluido:** este proyecto ya contiene archivos de estado. Antes de aplicar o destruir cambios, ejecuta `terraform -chdir=code state list` y revisa `terraform -chdir=code plan`. Si aparecen recursos que no creaste para tu propio ejercicio, detente y consulta al instructor. No borres ni reemplaces el estado compartido: hacerlo puede desvincular Terraform de recursos existentes.

## Paso 1: entender la configuracion

Abre `code/provider.tf`:

```hcl
provider "aws" {
	region = "us-east-1"
}
```

El provider es el complemento que permite a Terraform comunicarse con AWS. La region indica donde se crearan los recursos. La autenticacion se obtiene de las credenciales configuradas en tu entorno, no de este bloque.

Ahora revisa `code/bucket.tf`. El primer bloque declara seis buckets:

```hcl
resource "aws_s3_bucket" "s3mauro" {
	count  = 6
	bucket = "totallyti-cloud-${random_string.sufijo[count.index].id}"
	tags = {
		Owner       = "totallyti"
		Environment = "Dev"
		Office      = "Cloud"
	}
}
```

- `resource "aws_s3_bucket" "s3mauro"` declara un recurso de tipo bucket. `s3mauro` es su nombre local dentro de Terraform.
- `count = 6` crea seis instancias, identificadas por indices del `0` al `5`.
- `count.index` es el indice de la instancia actual. Se utiliza para elegir el sufijo correspondiente.
- `tags` agrega metadatos utiles para organizar e identificar recursos; las etiquetas no conceden permisos.

El segundo bloque crea los sufijos:

```hcl
resource "random_string" "sufijo" {
	count   = 6
	length  = 8
	special = false
	upper   = false
	numeric = false
}
```

El provider `random` genera seis cadenas de ocho letras minusculas. Terraform combina cada cadena con el prefijo `totallyti-cloud-` para formar el nombre de un bucket. Los nombres de buckets S3 deben ser unicos globalmente; si AWS informa que uno ya esta ocupado, el plan puede necesitar un nuevo sufijo.

## Paso 2: inicializar Terraform

Desde la raiz del proyecto, ejecuta:

```bash
terraform -chdir=code init
```

Este comando prepara el directorio de trabajo y descarga los providers requeridos (`aws` y `random`). Se puede repetir cuando cambian los providers o se prepara el entorno por primera vez.

## Paso 3: comprobar y validar

Da formato a la configuracion y valida su estructura:

```bash
terraform -chdir=code fmt
terraform -chdir=code validate
```

`fmt` aplica el formato canonico a los archivos `.tf`. `validate` comprueba la configuracion y sus referencias; no crea recursos en AWS.

## Paso 4: revisar el plan

Antes de crear nada, inspecciona el estado actual y el plan:

```bash
terraform -chdir=code state list
terraform -chdir=code plan
```

El plan muestra las acciones propuestas sin aplicarlas. Para una primera ejecucion limpia, espera ver seis recursos `aws_s3_bucket.s3mauro` y seis recursos `random_string.sufijo` por crear. Si el estado o el plan muestran cambios inesperados, no continues: confirma con tu instructor que estas trabajando sobre un estado aislado y correcto.

Terraform guarda el plan en el estado local cuando aplicas cambios. Trata los archivos de estado como datos importantes: pueden incluir identificadores y otros valores de infraestructura. No los publiques ni los compartas sin seguir las reglas del curso.

## Paso 5: crear los buckets

Solo despues de revisar el plan y confirmar que estas usando tu propio entorno, aplica la configuracion:

```bash
terraform -chdir=code apply
```

Terraform vuelve a mostrar las acciones y solicita confirmacion. Lee el resumen y escribe `yes` unicamente si coincide con lo esperado. El provider `random` genera los sufijos y AWS crea los buckets.

## Paso 6: verificar el resultado

Consulta los recursos que Terraform registra en el estado:

```bash
terraform -chdir=code state list
```

Deberias encontrar las instancias `aws_s3_bucket.s3mauro[0]` a `aws_s3_bucket.s3mauro[5]` y `random_string.sufijo[0]` a `random_string.sufijo[5]`. Tambien puedes comprobar los nombres en la consola de S3 de AWS. Este laboratorio no define bloques `output`, por lo que `terraform output` no mostrara nombres del proyecto.

## Paso 7: limpiar el laboratorio

Los buckets vacios normalmente no generan cargos de almacenamiento, pero los recursos de AWS y los datos que coloques en ellos pueden tener costos. Cuando hayas terminado y confirmado que los recursos pertenecen a tu ejercicio, elimínalos con:

```bash
terraform -chdir=code destroy
```

Revisa el plan de destruccion antes de confirmar. AWS no permite eliminar un bucket que contiene objetos; si agregaste objetos durante una prueba, elimínalos primero de forma segura. No ejecutes `destroy` sobre un estado compartido ni sobre recursos ajenos al laboratorio.

## Solucion de problemas

- **Error de credenciales o acceso denegado:** confirma que el perfil o rol de AWS activo es el correcto y que cuenta con permisos para las operaciones indicadas.
- **Nombre de bucket no disponible:** los nombres S3 son globales; vuelve a generar los sufijos con `terraform -chdir=code apply -replace='random_string.sufijo[0]'` y revisa el plan antes de confirmar. Repite para la instancia que corresponda si fuera necesario.
- **Error al destruir un bucket:** comprueba si contiene objetos y elimina unicamente los datos creados para este laboratorio antes de volver a ejecutar `destroy`.
- **Terraform muestra cambios inesperados:** detente y revisa el estado y el plan. No elimines archivos de estado para intentar corregirlo.

## Ideas para experimentar

Una vez completado el workshop, puedes cambiar el valor de `count` en ambos recursos para crear otra cantidad de buckets. Mantén ambos valores iguales porque cada bucket usa el sufijo con el mismo indice. Luego ejecuta `fmt`, `validate` y `plan` para observar el cambio antes de aplicarlo.