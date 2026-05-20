<?php

namespace App\Enums;

enum TransactionFlowStatus: string
{
    case PendingConfirmation = 'pending_confirmation';
    case PendingClarification = 'pending_clarification';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
