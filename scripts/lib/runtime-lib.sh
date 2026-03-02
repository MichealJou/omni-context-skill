#!/usr/bin/env bash

omni_runtime_kinds() {
  printf '%s\n' mysql postgres redis browser miniapp mq service
}

omni_runtime_is_dangerous_db_op() {
  case "${1^^}" in
    DROP|TRUNCATE|DELETE|ALTER|UPDATE) return 0 ;;
    *) return 1 ;;
  esac
}

omni_runtime_is_dangerous_redis_op() {
  case "${1^^}" in
    DEL|UNLINK|FLUSHDB|FLUSHALL|MSET|EVAL) return 0 ;;
    *) return 1 ;;
  esac
}
