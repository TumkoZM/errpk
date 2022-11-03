local settings = {}

settings.REPOSITORY = "https://raw.githubusercontent.com/Tumkov/bleb/main"
settings.TITLE = "Приветствуем ваc"
settings.ADMINS = { "Tumko" }

-- CHEST - Взаимодействие сундука и МЕ сети
-- PIM - Взаимодействие PIM и МЕ сети
-- CRYSTAL - Взаимодействие кристального сундука и алмазного сундука
-- DEV - Оплата не взимается, награда не выдается, не требует внешних компонентов
settings.PAYMENT_METHOD = "PIM"
settings.CONTAINER_PAY = "DOWN"
settings.CONTAINER_GAIN = "UP"

return settings;
