// Copyright 2026 BWI GmbH and Testkit contributors
// SPDX-License-Identifier: Apache-2.0

package container

import "github.com/ory/dockertest/v3"

type RunOptionFunc = func(options *dockertest.RunOptions)

// WithEnv applies the given key/value pairs in the format ENV_VAR=value to the environment
// of the container
func WithEnv(envKV ...string) RunOptionFunc {
	return func(options *dockertest.RunOptions) {
		if envKV != nil {
			options.Env = envKV
		}
	}
}

// WithExposedPorts makes all given ports (in the format '8080/tcp') accessible
func WithExposedPorts(ports ...string) RunOptionFunc {
	return func(opts *dockertest.RunOptions) {
		opts.ExposedPorts = ports
	}
}
