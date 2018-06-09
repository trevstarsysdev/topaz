// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package backend

import (
	"fidl/compiler/backend/types"
	"fidlgen_dart/backend/ir"
	"fidlgen_dart/backend/templates"
	"os"
	"text/template"
)

func writeFile(outputFilename string,
	templateName string,
	tmpls *template.Template,
	tree ir.Root) error {
	f, err := os.Create(outputFilename)
	if err != nil {
		return err
	}
	defer f.Close()
	return tmpls.ExecuteTemplate(f, templateName, tree)
}

// GenerateFidl generates Dart bindings from FIDL types structures.
func GenerateFidl(fidl types.Root, config *types.Config) error {
	tree := ir.Compile(fidl)

	tmpls := template.New("DartTemplates")
	template.Must(tmpls.Parse(templates.Const))
	template.Must(tmpls.Parse(templates.Enum))
	template.Must(tmpls.Parse(templates.Interface))
	template.Must(tmpls.Parse(templates.Library))
	template.Must(tmpls.Parse(templates.Struct))
	template.Must(tmpls.Parse(templates.Union))

	err := writeFile(config.OutputBase+"/fidl.dart", "GenerateLibraryFile", tmpls, tree)
	if err != nil {
		return err
	}

	return writeFile(config.OutputBase+"/fidl_async.dart", "GenerateAsyncFile", tmpls, tree)
}