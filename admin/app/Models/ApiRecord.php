<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * ApiRecord — API'den gelen veriyi Filament'in beklediği Eloquent Model'e sarmalar.
 * Filament'in getRecordAction() metodu Fluent değil, Model bekler.
 */
class ApiRecord extends Model
{
    // DB bağlantısı yok
    protected $connection = null;

    // Tüm alanları doldurulabilir yap
    protected $guarded = [];

    // Timestamp otomatik güncelleme yok
    public $timestamps = false;

    /**
     * Array verisini ApiRecord nesnesine çevirir
     */
    public static function fromArray(array $data): static
    {
        $instance = new static();
        $instance->setRawAttributes($data, true);
        // ID mutlaka set edilmeli — Filament recordKey için kullanır
        if (isset($data['id'])) {
            $instance->id = $data['id'];
        }
        return $instance;
    }

    /**
     * Eloquent koleksiyonlarında primary key lookup için
     */
    public function getKey()
    {
        return $this->getAttribute('id') ?? spl_object_id($this);
    }

    /**
     * Filament recordKey() için
     */
    public function getKeyName(): string
    {
        return 'id';
    }
}
