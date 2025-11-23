<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Account Confirmed - Hiotaku</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #0F0F23 0%, #1A1A2E 50%, #16213E 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        
        .container {
            text-align: center;
            padding: 40px 20px;
            max-width: 400px;
            width: 100%;
        }
        
        .logo {
            width: 80px;
            height: 80px;
            background: #64B5F6;
            border-radius: 20px;
            margin: 0 auto 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 32px;
            font-weight: bold;
            color: white;
            box-shadow: 0 10px 30px rgba(100, 181, 246, 0.3);
        }
        
        h1 {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 12px;
            color: white;
        }
        
        p {
            font-size: 16px;
            color: rgba(255, 255, 255, 0.7);
            margin-bottom: 30px;
            line-height: 1.5;
        }
        
        .btn {
            display: inline-block;
            background: linear-gradient(135deg, #64B5F6, #42A5F5);
            color: white;
            padding: 16px 32px;
            border-radius: 12px;
            text-decoration: none;
            font-weight: 600;
            font-size: 16px;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 8px 25px rgba(100, 181, 246, 0.4);
            border: none;
            cursor: pointer;
            margin: 8px;
        }
        
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 35px rgba(100, 181, 246, 0.5);
        }
        
        .btn:active {
            transform: translateY(0);
        }
        
        .status {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 12px;
            padding: 20px;
            margin-bottom: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .success {
            border-color: #4CAF50;
            background: rgba(76, 175, 80, 0.1);
        }
        
        .loading {
            display: inline-block;
            width: 20px;
            height: 20px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top-color: #64B5F6;
            animation: spin 1s ease-in-out infinite;
            margin-right: 10px;
        }
        
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        
        .footer {
            margin-top: 40px;
            font-size: 14px;
            color: rgba(255, 255, 255, 0.5);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">H</div>
        
        <div class="status success">
            <h1>Account Confirmed!</h1>
            <p>Your Hiotaku account has been successfully verified.</p>
        </div>
        
        <div id="redirect-status">
            <div class="loading"></div>
            <span>Opening Hiotaku app...</span>
        </div>
        
        <div style="margin-top: 20px;">
            <a href="hiotaku://confirm" class="btn" id="open-app">Open Hiotaku App</a>
            <br>
            <a href="https://play.google.com/store" class="btn" style="background: #34A853;">Download App</a>
        </div>
        
        <div class="footer">
            <p>Welcome to the ultimate anime community!</p>
        </div>
    </div>

    <script>
        // Auto redirect to app
        function redirectToApp() {
            document.getElementById('redirect-status').innerHTML = 
                '<div class="loading"></div><span>Opening Hiotaku app...</span>';
            
            // Try to open app
            window.location.href = 'hiotaku://confirm';
            
            // Fallback after 3 seconds
            setTimeout(function() {
                document.getElementById('redirect-status').innerHTML = 
                    '<p style="color: rgba(255,255,255,0.7);">App not installed? Use the button below:</p>';
            }, 3000);
        }
        
        // Auto redirect on page load
        setTimeout(redirectToApp, 1000);
        
        // Manual redirect button
        document.getElementById('open-app').addEventListener('click', function(e) {
            e.preventDefault();
            redirectToApp();
        });
    </script>
</body>
</html>
