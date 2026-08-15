#!/usr/bin/env bash

selftest_duplicate_a() { :; }
selftest_duplicate_b() { :; }

register_case duplicate same fast 1 selftest_duplicate_a
register_case duplicate same fast 1 selftest_duplicate_b
