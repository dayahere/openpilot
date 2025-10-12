import React, { useState } from 'react';

const CodeGenPage: React.FC = () => {
  const [prompt, setPrompt] = useState('');
  const [generatedCode, setGeneratedCode] = useState('');
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    if (!prompt.trim()) return;
    
    setLoading(true);
    // Simulate code generation
    setTimeout(() => {
      setGeneratedCode(`// Generated code for: ${prompt}\n\nfunction example() {\n  console.log("Code generation placeholder");\n  // Connect to OpenPilot AI for actual generation\n}\n\nexample();`);
      setLoading(false);
    }, 1000);
  };

  return (
    <div className="codegen-page">
      <h2>Code Generation</h2>
      <div className="codegen-container">
        <div className="prompt-section">
          <label>Describe what code you want to generate:</label>
          <textarea
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="E.g., Create a function that sorts an array..."
            rows={5}
          />
          <button onClick={handleGenerate} disabled={loading}>
            {loading ? 'Generating...' : 'Generate Code'}
          </button>
        </div>
        {generatedCode && (
          <div className="code-output">
            <h3>Generated Code:</h3>
            <pre><code>{generatedCode}</code></pre>
          </div>
        )}
      </div>
    </div>
  );
};

export default CodeGenPage;
