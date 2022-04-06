var pyodide = null;

async function initPyodide() {
    // Don't reload pyodide if we're hot reloading
    updatePyodideProgress(0.0, "Loading Pyodide");
    if (pyodide == null) {
        pyodide = await loadPyodide({
            indexURL: "https://cdn.jsdelivr.net/pyodide/v0.19.0/full/"
        });
    }
    updatePyodideProgress(0.1, "Loading micropip");
    await pyodide.loadPackage("micropip");
    updatePyodideProgress(0.35, "Importing micropip");
    await pyodide.runPythonAsync("import micropip");
    updatePyodideProgress(0.55, "Installing dh2vrml");
    await pyodide.runPythonAsync("await micropip.install('dh2vrml==0.1.9')");
    updatePyodideProgress(0.85, "Importing dh2vrml");
    await pyodide.runPythonAsync("import dh2vrml");
    await pyodide.runPythonAsync("from dh2vrml import cli");
    updatePyodideProgress(0.95, "Checking version");
    version = await pyodide.runPythonAsync(`
    version = dh2vrml.__version__
    print(f'Running dh2vrml version {version}')
    version
    `);
    updatePyodideProgress(1.0, `dh2vrml version ${version} loaded`);
}

async function writePyodideFile(fileName, fileData) {
    pyodide.globals.set("file_name", fileName);
    pyodide.globals.set("file_data", fileData);
    await pyodide.runPythonAsync(`
    with open(file_name, "w") as f:
      f.write(file_data)
    `)

    // Read back data to ensure it exists
    data = await pyodide.runPythonAsync(`
    with open(file_name, "r") as f:
      data = f.read()
    data
    `)
    return data
}

async function generateX3DFile(fileName) {
    pyodide.globals.set("file_name", fileName);
    modelXML = await pyodide.runPythonAsync(`
    from dh2vrml import cli
    params = cli.get_params_from_file(file_name)
    modelXML = cli.write_x3d_file(
        file_name,
        params,
        (10, -10, 10),
        (0, 0, 0),
        False # Can't validate in pyodide
    )
    modelXML
    `);
    return modelXML;
}