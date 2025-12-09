try {
    console.log('Loading chat routes...');
    require('./routes/chat.routes');
    console.log('Chat routes loaded.');

    console.log('Loading user routes...');
    require('./routes/user.routes');
    console.log('User routes loaded.');

    console.log('All routes loaded successfully.');
} catch (error) {
    console.error('Error loading routes:', error);
}
