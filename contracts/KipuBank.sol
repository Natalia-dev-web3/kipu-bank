// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 * @author Natalia Avila
 * @notice Contrato de bóveda bancaria que permite a los usuarios depositar y retirar ETH
 * @dev Implementa patrones de seguridad y buenas prácticas de Solidity
 */
contract KipuBank {
    //Variables de Estado

    /// @notice Límite máximo de depósitos que puede contener el banco
    /// @dev Establecido en el constructor y no puede ser modificado
    uint256 public immutable BANK_CAP;

    /// @notice Límite máximo que un usuario puede retirar por transacción
    /// @dev Constante que previene retiros masivos instantáneos
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;

    /// @notice Mapeo de direcciones de usuarios a sus balances en la bóveda
    mapping(address => uint256) private s_userVaults;

    /// @notice Contador total de depósitos realizados en el banco
    uint256 private s_totalDeposits;

    /// @notice Contador total de retiros realizados en el banco
    uint256 private s_totalWithdrawals;

    //Eventos

    /// @notice Emitido cuando un usuario realiza un depósito exitoso
    /// @param user Dirección del usuario que depositó
    /// @param amount Cantidad de ETH depositada
    /// @param newBalance Nuevo balance del usuario en la bóveda
    event Deposit(address indexed user, uint256 amount, uint256 newBalance);

    /// @notice Emitido cuando un usuario realiza un retiro exitoso
    /// @param user Dirección del usuario que retiró
    /// @param amount Cantidad de ETH retirada
    /// @param newBalance Nuevo balance del usuario en la bóveda
    event Withdrawal(address indexed user, uint256 amount, uint256 newBalance);

    //Errores personalizados

    /// @notice Error cuando el monto del depósito es cero
    error KipuBank__DepositAmountMustBeGreaterThanZero();

    /// @notice Error cuando el depósito excede el límite del banco
    /// @param attempted Monto que se intentó depositar
    /// @param available Espacio disponible en el banco
    error KipuBank__DepositExceedsBankCap(uint256 attempted, uint256 available);

    /// @notice Error cuando el monto del retiro es cero
    error KipuBank__WithdrawalAmountMustBeGreaterThanZero();

    /// @notice Error cuando el retiro excede el límite por transacción
    /// @param attempted Monto que se intentó retirar
    /// @param limit Límite máximo permitido
    error KipuBank__WithdrawalExceedsLimit(uint256 attempted, uint256 limit);

    /// @notice Error cuando el usuario no tiene fondos suficientes
    /// @param requested Monto solicitado
    /// @param available Balance disponible
    error KipuBank__InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Error cuando la transferencia de ETH falla
    error KipuBank__TransferFailed();

    //Notificadores

    /// @notice Verifica que el monto sea mayor que cero
    /// @param amount Monto a verificar
    modifier amountGreaterThanZero(uint256 amount) {
        if (amount == 0) {
            revert KipuBank__DepositAmountMustBeGreaterThanZero();
        }
        _;
    }

    //Constructor

    /// @notice Inicializa el contrato con el límite máximo del banco
    /// @param bankCap Límite máximo de ETH que puede contener el banco
    constructor(uint256 bankCap) {
        BANK_CAP = bankCap;
    }

    //Funciones Externas

    /// @notice Permite a los usuarios depositar ETH en su bóveda personal
    /// @dev Aplica checks-effects-interactions. Revierte si excede BANK_CAP
    function deposit() external payable amountGreaterThanZero(msg.value) {
        // Checks: Verificar que el depósito no exceda el límite del banco
        uint256 currentBankBalance = address(this).balance - msg.value;
        uint256 newBankBalance = currentBankBalance + msg.value;
        
        if (newBankBalance > BANK_CAP) {
            uint256 availableSpace = BANK_CAP - currentBankBalance;
            revert KipuBank__DepositExceedsBankCap(msg.value, availableSpace);
        }

        // Effects: Actualizar el estado antes de cualquier interacción externa
        s_userVaults[msg.sender] += msg.value;
        s_totalDeposits++;
        
        uint256 newUserBalance = s_userVaults[msg.sender];

        // Interactions: Emitir evento (última acción)
        emit Deposit(msg.sender, msg.value, newUserBalance);
    }

    /// @notice Permite a los usuarios retirar ETH de su bóveda personal
    /// @param amount Cantidad de ETH a retirar
    /// @dev Aplica checks-effects-interactions y validaciones de seguridad
    function withdraw(uint256 amount) external amountGreaterThanZero(amount) {
        // Checks: Validar límite de retiro
        if (amount > WITHDRAWAL_LIMIT) {
            revert KipuBank__WithdrawalExceedsLimit(amount, WITHDRAWAL_LIMIT);
        }

        // Checks: Validar balance suficiente
        uint256 userBalance = s_userVaults[msg.sender];
        if (amount > userBalance) {
            revert KipuBank__InsufficientBalance(amount, userBalance);
        }

        // Effects: Actualizar el estado antes de transferir
        s_userVaults[msg.sender] -= amount;
        s_totalWithdrawals++;
        
        uint256 newUserBalance = s_userVaults[msg.sender];

        // Interactions: Transferir ETH de forma segura
        _safeTransferETH(msg.sender, amount);

        // Emitir evento después de la transferencia exitosa
        emit Withdrawal(msg.sender, amount, newUserBalance);
    }

    /// @notice Obtiene el balance de la bóveda de un usuario
    /// @param user Dirección del usuario a consultar
    /// @return Balance actual del usuario en la bóveda
    function getUserVaultBalance(address user) external view returns (uint256) {
        return s_userVaults[user];
    }

    /// @notice Obtiene el número total de depósitos realizados
    /// @return Contador de depósitos totales
    function getTotalDeposits() external view returns (uint256) {
        return s_totalDeposits;
    }

    /// @notice Obtiene el número total de retiros realizados
    /// @return Contador de retiros totales
    function getTotalWithdrawals() external view returns (uint256) {
        return s_totalWithdrawals;
    }

    /// @notice Obtiene el balance total del banco
    /// @return Balance total de ETH en el contrato
    function getBankBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Obtiene el espacio disponible para nuevos depósitos
    /// @return Cantidad de ETH que aún se puede depositar
    function getAvailableSpace() external view returns (uint256) {
        uint256 currentBalance = address(this).balance;
        if (currentBalance >= BANK_CAP) {
            return 0;
        }
        return BANK_CAP - currentBalance;
    }

    //Funciones privadas

    /// @notice Transfiere ETH de forma segura usando call
    /// @param to Dirección destino
    /// @param amount Cantidad a transferir
    /// @dev Revierte si la transferencia falla
    function _safeTransferETH(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{value: amount}("");
        if (!success) {
            revert KipuBank__TransferFailed();
        }
