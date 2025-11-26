const nodemailer = require('nodemailer');

// Configurar transporter de Gmail
const transporter = nodemailer.createTransporter({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER, // Tu email de Gmail
        pass: process.env.EMAIL_APP_PASSWORD // App Password de Gmail
    }
});

/**
 * Genera un código aleatorio de 6 dígitos
 */
function generateVerificationCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Envía un código de verificación por email
 * @param {string} email - Email del destinatario
 * @param {string} code - Código de 6 dígitos
 * @param {string} userName - Nombre del usuario
 */
async function sendVerificationEmail(email, code, userName = 'Usuario') {
    const mailOptions = {
        from: `UniHitch <${process.env.EMAIL_USER}>`,
        to: email,
        subject: '🔐 Código de Verificación - UniHitch',
        html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .code { font-size: 32px; font-weight: bold; letter-spacing: 5px; text-align: center; background: white; padding: 20px; margin: 20px 0; border-radius: 8px; border: 2px dashed #667eea; }
          .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚗 UniHitch</h1>
            <p>Verificación de Email</p>
          </div>
          <div class="content">
            <h2>¡Hola ${userName}!</h2>
            <p>Gracias por registrarte en UniHitch. Para completar tu registro, ingresa el siguiente código de verificación:</p>
            
            <div class="code">${code}</div>
            
            <p><strong>Este código expira en 15 minutos.</strong></p>
            
            <p>Si no solicitaste este código, ignora este email.</p>
          </div>
          <div class="footer">
            <p>© 2025 UniHitch - Tu plataforma de viajes compartidos universitarios</p>
          </div>
        </div>
      </body>
      </html>
    `
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('✉️ Email enviado:', info.messageId);
        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('❌ Error enviando email:', error);
        throw error;
    }
}

/**
 * Envía notificación de documentos aprobados
 */
async function sendDocumentsApprovedEmail(email, userName) {
    const mailOptions = {
        from: `UniHitch <${process.env.EMAIL_USER}>`,
        to: email,
        subject: '✅ Documentos Aprobados - Ya puedes ofrecer viajes',
        html: `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2>¡Felicidades ${userName}!</h2>
          <p>Tus documentos han sido verificados y aprobados.</p>
          <p>Ya puedes empezar a ofrecer viajes en UniHitch. 🚗</p>
          <p><strong>Próximos pasos:</strong></p>
          <ul>
            <li>Abre la app UniHitch</li>
            <li>Toca "Ofrecer Viaje"</li>
            <li>Completa los detalles de tu viaje</li>
            <li>¡Empieza a ganar dinero compartiendo tu auto!</li>
          </ul>
        </div>
      </body>
      </html>
    `
    };

    return await transporter.sendMail(mailOptions);
}

/**
 * Envía notificación de documentos rechazados
 */
async function sendDocumentsRejectedEmail(email, userName, reason) {
    const mailOptions = {
        from: `UniHitch <${process.env.EMAIL_USER}>`,
        to: email,
        subject: '❌ Documentos Rechazados - Se requiere nueva revisión',
        html: `
      <!DOCTYPE html>
      <html>
      <body style="font-family: Arial, sans-serif;">
        <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2>Hola ${userName}</h2>
          <p>Lamentablemente, tus documentos no pudieron ser aprobados.</p>
          <p><strong>Motivo:</strong> ${reason}</p>
          <p>Por favor, revisa tus documentos y vuelve a subirlos.</p>
          <p><strong>¿Qué hacer?</strong></p>
          <ul>
            <li>Verifica que las imágenes/PDFs sean claros y legibles</li>
            <li>Asegúrate que los documentos estén vigentes</li>
            <li>Vuelve a subir los documentos en la app</li>
          </ul>
        </div>
      </body>
      </html>
    `
    };

    return await transporter.sendMail(mailOptions);
}

module.exports = {
    generateVerificationCode,
    sendVerificationEmail,
    sendDocumentsApprovedEmail,
    sendDocumentsRejectedEmail
};
