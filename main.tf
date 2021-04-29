terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = ">=2.11"
    }

  }
  required_version = ">= 0.13"
}

# Configure the Docker provider
provider "docker" {
  //host = "ssh://root@docker-dev.emse.fr:22"
  host = "ssh://root@192.168.0.150:22"
}

variable "wordpresses" {
  description = "Map of project names to configuration."
  type        = map
  default     = {
    intranet = {
      name= "Intranet"
      dns="intranet"
      mysql_pass="azertyu"
    },
    extranet = {
      name= "Extranet"
      dns="extranet"
      mysql_pass="azertyiop"
    },
  }
}



variable "domain"{
  type = string
  default ="docker-dev.emse.fr"
}

resource "docker_network" "private_network" {
  
  name = "wp_net"

}



resource "docker_volume" "wp_vol_db" {
  for_each = var.wordpresses
  name = "wp_vol_db_${var.wordpresses[each.key].dns}"

}



resource "docker_volume" "wp_vol_html" {

    for_each = var.wordpresses
  name = "wp_vol_html_${var.wordpresses[each.key].dns}"

}


//Database
resource "docker_container" "db" {

  for_each = var.wordpresses

  name  = "db_${var.wordpresses[each.key].dns}"

  image = "mariadb"

  restart = "always"

  network_mode = "wp_net"

  mounts {

    type = "volume"

    target = "/var/lib/mysql"

    source = "wp_vol_db_${var.wordpresses[each.key].dns}"

  }

  env = [

     "MYSQL_ROOT_PASSWORD=r${var.wordpresses[each.key].mysql_pass}!",

     "MYSQL_DATABASE=wordpress",

     "MYSQL_USER=${var.wordpresses[each.key].dns}",

     "MYSQL_PASSWORD=${var.wordpresses[each.key].mysql_pass}"

  ]

}


//Lemp + wordpress
resource "docker_container" "wordpress" {

  for_each = var.wordpresses

  name  = "wordpress_${var.wordpresses[each.key].dns}"

  image = "wordpress:latest"

  restart = "always"

  network_mode = "wp_net"

  env = [

    "WORDPRESS_DB_HOST=db_${var.wordpresses[each.key].dns}",

    "WORDPRESS_DB_USER=${var.wordpresses[each.key].dns}",

    "WORDPRESS_DB_PASSWORD=${var.wordpresses[each.key].mysql_pass}",

    "WORDPRESS_DB_NAME=wordpress",

    "VIRTUAL_HOST=wp.${var.domain}"



  ]


  mounts {

    type = "volume"

    target = "/var/www/html"

    source = "wp_vol_html_${var.wordpresses[each.key].dns}"

  }

}

resource "docker_container" "reverseproxy"{
  name="Reverse_Proxy_Jwilder"

  image="jwilder/nginx-proxy"

  restart="always"

  network_mode = "wp_net"

  ports {

    internal = "80"

    external = "9080"

  }

    mounts {

    type = "bind"

    source = "/var/run/docker.sock"

    target = "/tmp/docker.sock"



  }




}

//grafana
resource "docker_container" "grafana" {
  name="grafana"

  image="grafana/grafana"

    ports {

    internal = "3000"

    external = "3000"

  }
  env=[
    "VIRTUAL_HOST=graf.${var.domain}"
  ]

}



