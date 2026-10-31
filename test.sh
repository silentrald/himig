#!/bin/bash

if [[ $1 == "unit" ]] then
  echo "Doing unit tests"
  flutter test test/unit/**/*
elif [[ $1 == "integration" ]] then
  echo "Doing integration tests"
  flutter test test/integration/**/*
else
  echo "No test specified (unit/integration)"
fi


