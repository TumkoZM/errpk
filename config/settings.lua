local settings = {}

settings.REPOSITORY = "https://raw.githubusercontent.com/TumkoZM/errpk/main"
settings.TITLE = ""
settings.ADMINS = {"Tumko", "OrdiName"}

-- CHEST - Взаимодействие сундука и МЕ сети
-- PIM - Взаимодействие PIM и МЕ сети
-- CRYSTAL - Взаимодействие кристального сундука и алмазного сундука
-- DEV - Оплата не взимается, награда не выдается, не требует внешних компонентов
settings.PAYMENT_METHOD = "PIM"
settings.CONTAINER_PAY = "DOWN"
settings.CONTAINER_GAIN = "UP"

return settings;
