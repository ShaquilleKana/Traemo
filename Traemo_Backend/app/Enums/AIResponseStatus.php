<?php

namespace App\Enums;

enum AIResponseStatus: string
{
    case Success = 'success';
    case NeedClarification = 'need_clarification';
    case Invalid = 'invalid';
}
