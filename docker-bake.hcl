variable "VERSION" {
    default = "0.1.0"
}
variable "NGINX_MAINLINE" {
    default = "UNSET"
}
variable "CORE_COUNT" {
    default = "1"
}

group "default" {
    targets = ["deb"]
}

target "deb" {
    dockerfile = "Dockerfile"
    target = "final"
    output = ["artifacts"]
    args = {
        NGINX_VER="${NGINX_MAINLINE}"
        CORE_COUNT="${CORE_COUNT}"
        VERSION="${VERSION}"
    }
}