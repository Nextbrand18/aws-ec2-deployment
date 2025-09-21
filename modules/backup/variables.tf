variable "backups" {
  type = map(object({ 
    name = string
    schedule = string 
    }))
  default = {}
}
variable "tags" { 
  type = map(string) 
  default = {} 
  }
