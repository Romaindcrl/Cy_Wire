#include "../include/station.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

Station *station_create(const char *id, double capacity, double consumption) {
  Station *station = (Station *)malloc(sizeof(Station));
  if (!station)
    return NULL;

  station->id = strdup(id);
  if (!station->id) {
    free(station);
    return NULL;
  }

  station->capacity = capacity;
  station->consumption = consumption;
  return station;
}

void station_destroy(Station *station) {
  if (station) {
    free(station->id);
    free(station);
  }
}

int station_compare(const Station *s1, const Station *s2) {
  return strcmp(s1->id, s2->id);
}

void station_print(const Station *station) {
  printf("%s:%.2f:%.2f\n", station->id, station->capacity,
         station->consumption);
}
