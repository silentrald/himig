#!/bin/bash

if [[ $1 == "unit" ]] then
  echo "Doing unit tests"
  flutter test test/unit/**/*
else
  echo "No test specified (unit/integration)"
fi


