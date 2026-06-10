<?php

namespace App\Models;

use DateTimeInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Transaction extends Model
{
    public const UPDATED_AT = null;

    protected $fillable = [
        'user_id',
        'transaction_category_id',
        'amount',
        'description',
    ];

    protected $appends = [
        'type',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(TransactionCategory::class, 'transaction_category_id');
    }

    public function chats(): HasMany
    {
        return $this->hasMany(Chat::class);
    }

    protected function type(): Attribute
    {
        return Attribute::get(fn () => $this->category?->type);
    }

    protected function serializeDate(DateTimeInterface $date): string
    {
        return $date->format('Y-m-d H:i:s');
    }
}
