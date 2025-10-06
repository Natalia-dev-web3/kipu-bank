# KipuBank

Contrato inteligente de bóveda bancaria desarrollado para el Módulo 2 del Ethereum Developer Pack.

## Descripción

KipuBank es un contrato inteligente que funciona como un banco descentralizado donde cada usuario tiene su propia bóveda personal.

**Funcionalidades:**
- Depositar ETH en bóveda personal
- Retirar ETH con límite de 1 ETH por transacción
- Límite global del banco de 10 ETH (BANK_CAP)
- Eventos que registran todas las operaciones
- Contadores de depósitos y retiros totales

**Componentes implementados:**
- Variables immutable: BANK_CAP
- Variables constant: WITHDRAWAL_LIMIT
- Mapping: s_userVaults
- Variables de almacenamiento: s_totalDeposits, s_totalWithdrawals
- Eventos: Deposit, Withdrawal
- Errores personalizados
- Modificador: amountGreaterThanZero
- Constructor
- Función external payable: deposit()
- Función privada: _safeTransferETH()
- Funciones external view

## Instrucciones de Despliegue

**Red:** Sepolia Testnet  
**Dirección del contrato:** `0xC0a8dF3e4cEE100ee2dD24f558c41525A65010F1`  
**Verificar:** https://sepolia.etherscan.io/address/0xC0a8dF3e4cEE100ee2dD24f558c41525A65010F1

**Pasos realizados:**
1. Abrir Remix IDE (https://remix.ethereum.org)
2. Crear contracts/KipuBank.sol
3. Compilar con Solidity 0.8.26
4. Deploy & Run → Injected Provider - MetaMask
5. Conectar MetaMask a Sepolia
6. Constructor: 10000000000000000000 (10 ETH)
7. Deploy y confirmar transacción

## Cómo Interactuar con el Contrato

### Desde Etherscan

1. Ir a la dirección del contrato en Sepolia Etherscan
2. Pestaña "Contract"

**Depositar:**
- "Write Contract" → Conectar wallet
- Función deposit → Ingresar cantidad en "value"

**Retirar:**
- Función withdraw
- amount: cantidad en wei (máximo 1000000000000000000)

**Consultar:**
- "Read Contract"
- getUserVaultBalance: consultar balance por dirección

### Desde Remix

1. Deploy & Run → Injected Provider
2. Conectar a Sepolia
3. "At Address": 0xC0a8dF3e4cEE100ee2dD24f558c41525A65010F1
4. Interactuar con funciones

## Autor

Natalia  
GitHub: https://github.com/Natalia-dev-web3
