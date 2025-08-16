# TP4

Infraestructura mínima para:
1. VM Windows (disco ≥ 50 GB) con acceso remoto controlado por NSG.
2. Azure Function (Node 20) que copia blobs desde el Storage origen (`incoming/`) al Storage destino (`processed/`).
3. Azure Container App desplegada con Terraform via Jenkins.

## Requisitos
- Azure CLI, Terraform >= 1.6
- Resource Group existente: `rg-cbechi`
- Credenciales Azure en Jenkins con IDs: `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

---
## 1) VM Windows

**Ruta:** `1-vm-windows/`

1. Copiar variables de ejemplo y revisar:
   ```bash
   cd 1-vm-windows
   cp terraform.tfvars.example terraform.tfvars
   # Valores por defecto:
   # resource_group_name = "rg-cbechi"
   # admin_username      = "cbechi"
   # admin_password      = "TrabajoPractico4"
   # allow_rdp           = false
   ```
2. Inicializar y aplicar:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
3. Salidas: `public_ip`, `username`.

> Para la corrección, establecer `allow_rdp = true` y aplicar nuevamente. Opcionalmente cambiar contraseña y deshabilitar RDP al finalizar.

---
## 2) Function: copiar origen → destino

**Infra:** `2-function-copy/infra`  
**Código:** `2-function-copy/function`

1. Infraestructura:
   ```bash
   cd 2-function-copy/infra
   cp terraform.tfvars.example terraform.tfvars
   terraform init
   terraform apply -auto-approve
   # Outputs: function_name, source_account_name, dest_account_name
   ```
2. Despliegue de código (requiere Azure CLI):
   ```bash
   cd ..
   bash deploy_function.sh
   ```
3. Prueba rápida (subir un archivo al contenedor `incoming` del Storage origen). El archivo debe aparecer en `processed` del Storage destino.

---
## 3) Container App con Jenkins

**Ruta:** `3-containerapp/infra`

- Jenkinsfile en la raíz del repo. El pipeline ejecuta `init/plan/apply` y muestra el FQDN.
- Variables (por defecto) en `3-containerapp/infra/terraform.tfvars.example`.

### Ejecución manual opcional
```bash
cd 3-containerapp/infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -auto-approve
terraform output -raw app_fqdn
```

---
## Notas
- Los nombres de cuentas de Storage incluyen un sufijo aleatorio para evitar colisiones.
- La Function usa `AzureWebJobsSourceStorage` como origen y `DEST_CONNECTION` hacia destino.
- La VM, la Function y la Container App se crean en el `rg-cbechi` existente.
